//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Temporal SDK open source project
//
// Copyright (c) 2025 Apple Inc. and the Swift Temporal SDK project authors
// Licensed under MIT License
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Swift Cassandra Client project authors
//
// SPDX-License-Identifier: MIT
//
//===----------------------------------------------------------------------===//

import Logging

/// A workflow runner is responsible for handling a single instance of a workflow.
///
/// This type processes new workflow activations, handles the workflow's executor and sends any outbound commands.
struct WorkflowInstance: Sendable {
    /// Task local indicating whether the workflow state is currently frozen.
    ///
    /// When frozen, workflow operations are blocked to ensure deterministic execution. It is frozen in the following cases:
    /// - Workflow initialization
    /// - Query execution
    /// - Update validation handler
    /// - Intercepting calls
    @TaskLocal
    static var isWorkflowStateFrozen: Bool = false

    /// Task local indicating whether code is currently running on the WorkflowInstance.
    ///
    /// When true, ``WorkflowStateMachineStorage`` methods are allowed to be called from off the executor.
    // swift-format-ignore: DontRepeatTypeInStaticProperties
    @TaskLocal
    static var isOnWorkflowInstance: Bool = false

    /// The task queue.
    private var taskQueue: String
    /// The worker's namespace.
    private var namespace: String
    /// The workflow's executor.
    private let executor: WorkflowTaskExecutor
    /// The workflow worker complete workflow activation closure.
    private let workflowWorkerCompleteWorkflowActivation:
        @Sendable (
            _ completion: consuming Coresdk_WorkflowCompletion_WorkflowActivationCompletion
        ) async throws -> Void
    /// The workflow's state machine.
    private let stateMachine: WorkflowStateMachineStorage
    /// The payload converter.
    private let payloadConverter: any PayloadConverter
    /// The failure converter.
    private let failureConverter: any FailureConverter
    /// The interceptor chain for inbound interceptors.
    private let implementation: Implementation
    /// The workflow outbound interceptor chain.
    private let outboundInterceptors: [any WorkflowOutboundInterceptor]
    /// The workflow instance logger.
    private let logger: Logger

    init<WorkflowWorker: WorkflowWorkerProtocol>(
        workflowWorker: WorkflowWorker,
        taskQueue: String,
        namespace: String,
        payloadConverter: any PayloadConverter,
        failureConverter: any FailureConverter,
        logger: Logger
    ) {
        self.workflowWorkerCompleteWorkflowActivation = workflowWorker.completeWorkflowActivation
        self.taskQueue = taskQueue
        self.namespace = namespace
        self.payloadConverter = payloadConverter
        self.failureConverter = failureConverter
        self.executor = .init()
        self.stateMachine = .init(
            executor: self.executor,
            payloadConverter: payloadConverter,
            failureConverter: failureConverter
        )
        let inboundInterceptors = workflowWorker.interceptors.compactMap { $0.makeWorkflowInboundInterceptor() }
        self.implementation = .init(interceptors: inboundInterceptors)
        self.outboundInterceptors = workflowWorker.interceptors.compactMap { $0.makeWorkflowOutboundInterceptor() }
        self.logger = logger
    }

    func run<Workflow: WorkflowDefinition>(
        workflowType: Workflow.Type,
        activations: some AsyncSequence<Coresdk_WorkflowActivation_WorkflowActivation, Never>
    ) async throws {
        var activationsIterator = activations.makeAsyncIterator()

        guard let activation = await activationsIterator.next(isolation: #isolation) else {
            // TODO: Add a log
            // This is weird but we can handle it. We should always have a single activation when
            // we start a workflow.
            return
        }

        self.updateActivation(activation)

        // The order of the following things is important
        // 1. Create the workflow instance if needed
        // 2. Apply all jobs
        // 3. Schedule the workflows run method if needed
        // 4. Run all executor jobs until everything suspended
        // 5. Check if any wait condition is satisfied and resume
        // 6. Continue from 4. until all wait conditions are checked

        // 1.
        let workflow: WorkflowTaskExecutorIsolatedBox<Workflow>
        let input: WorkflowTaskExecutorIsolatedBox<Workflow.Input>
        let workflowContext: WorkflowContext
        do {
            (workflow, input, workflowContext) = try await self.initializeWorkflow(
                activation,
                workflowType: workflowType
            )
        } catch {
            // We failed to initialize the workflow. This indicates a workflow task failure
            // so let's fail the activation and return here.
            let temporalFailure = self.failureConverter.convertError(
                error,
                payloadConverter: self.payloadConverter
            )
            try await self.workflowWorkerCompleteWorkflowActivation(
                .with {
                    $0.runID = activation.runID
                    $0.status = .failed(
                        .with {
                            $0.failure = .init(temporalFailure: temporalFailure)
                        }
                    )
                }
            )
            return
        }

        try await withThrowingTaskGroup(of: Void.self) { group in
            // 2.
            await self.applyJobs(
                jobs: activation.jobs,
                workflow: workflow,
                workflowContext: workflowContext,
                group: &group
            )

            // 3.
            self.startWorkflow(
                workflow: workflow,
                input: input,
                workflowContext: workflowContext,
                group: &group
            )

            // 4.-6.
            self.runExecutor(context: workflowContext)

            // We are finished applying the very first activation
            // We have to send the activation completion now

            // If this throws we will tear everything down and exit since
            // it indicates we failed to send the completion to the worker
            // which we cannot recover from
            try await self.completeActivation(activation: activation)

            // The following does steps 2-6 for every new activation
            self.logger.trace("Waiting for next activation")
            while let activation = await activationsIterator.next(isolation: #isolation) {
                updateActivation(activation)

                // 2.
                await self.applyJobs(
                    jobs: activation.jobs,
                    workflow: workflow,
                    workflowContext: workflowContext,
                    group: &group
                )

                // 4.-6.
                self.runExecutor(context: workflowContext)

                // If this throws we will tear everything down and exit since
                // it indicates we failed to send the completion to the worker
                // which we cannot recover from
                try await self.completeActivation(activation: activation)
            }

            // If we arrive here it means our workflow is removed from the cache and
            // we need to clean up our state i.e. cancel the workflow's run method and
            // all handlers.
            self.logger.trace("No more activations. Cancelling task group")
            // Cancelling is also modifying the state machine through continuations
            Self.$isOnWorkflowInstance.withValue(true) {
                group.cancelAll()
            }

            // In some cases an activity may not be resolved (non-deterministic error
            // when replaying for a query). We can't leave a hanging cancellation
            // otherwise the task group will never return.
            Self.$isOnWorkflowInstance.withValue(true) {
                stateMachine.forceCancelOutstandingContinuations()
            }

            // There might be outstanding continuations for wait conditions, activities, etc.. The cancel
            // should resume them but we have to run the executor one more time for the workflow run method
            // and any message handler to finish.
            self.runExecutor(context: workflowContext)
        }
    }

    /// Intializes the workflow.
    private func initializeWorkflow<Workflow: WorkflowDefinition>(
        _ activation: Coresdk_WorkflowActivation_WorkflowActivation,
        workflowType: Workflow.Type
    ) async throws -> (WorkflowTaskExecutorIsolatedBox<Workflow>, WorkflowTaskExecutorIsolatedBox<Workflow.Input>, WorkflowContext) {
        guard case .initializeWorkflow(let initializeWorkflow) = activation.jobs.first?.variant else {
            throw ArgumentError(
                message: "Expected first job to be initialize workflow job"
            )
        }
        let input: Workflow.Input
        if Workflow.Input.self == Void.self {
            input = () as! Workflow.Input
        } else {
            input = try self.payloadConverter.convertPayloads(
                initializeWorkflow.arguments.map { TemporalPayload(temporalAPIPayload: $0) },
                as: (Workflow.Input).self
            )
        }

        // Initially setting memo, search attributes and random seed.
        try Self.$isOnWorkflowInstance.withValue(true) {
            self.stateMachine.setMemo(initializeWorkflow.memo.fields.mapValues { .init(.init(temporalAPIPayload: $0)) })
            self.stateMachine.setSearchAttributes(try .init(initializeWorkflow.searchAttributes))
            self.stateMachine.updateRandomnessSeed(initializeWorkflow.randomnessSeed)
        }

        let workflowContext = WorkflowContext(
            stateMachine: self.stateMachine,
            workflowInfo: WorkflowInfo(
                initializeWorkflow: initializeWorkflow,
                runID: activation.runID,
                taskQueue: self.taskQueue,
                namespace: self.namespace,
                payloadConverter: self.payloadConverter,
                failureConverter: self.failureConverter
            ),
            payloadConverter: self.payloadConverter,
            outboundInterceptors: self.outboundInterceptors,
            logger: self.logger,
        )

        let workflowBox = WorkflowTaskExecutorIsolatedBox(
            executor: self.executor,
            wrapped: Self.$isWorkflowStateFrozen.withValue(true) {
                // Context is available but frozen during initialization
                // WorkflowContext.current will return nil due to frozen state
                return Workflow(input: input)
            }
        )
        let inputBox = WorkflowTaskExecutorIsolatedBox(
            executor: self.executor,
            wrapped: input
        )
        return (workflowBox, inputBox, workflowContext)
    }

    // Starts the workflows run method in a separate child task
    private func startWorkflow<Workflow: WorkflowDefinition>(
        workflow: WorkflowTaskExecutorIsolatedBox<Workflow>,
        input: WorkflowTaskExecutorIsolatedBox<Workflow.Input>,
        workflowContext: WorkflowContext,
        group: inout ThrowingTaskGroup<Void, any Error>
    ) {
        group.addTask(executorPreference: self.executor) {
            self.logger.trace("Intercepting workflow")
            let workflowResult = await Result {
                // Context is not frozen during normal workflow execution
                try await self.implementation.executeWorkflow(
                    workflow: workflow.wrapped,
                    context: workflowContext,
                    input: .init(
                        headers: workflowContext.info.headers,
                        input: input.wrapped
                    )
                )
            }

            switch workflowResult {
            case .success(let output):
                self.logger.trace("Workflow finished")
                let dataConversionResult = await Result { () async throws -> TemporalPayload in
                    try self.payloadConverter.convertValueHandlingVoid(output)
                }
                switch dataConversionResult {
                case .success(let temporalPayload):
                    self.stateMachine.workflowFinished(temporalPayload: temporalPayload)
                case .failure(let error):
                    let temporalFailure = self.failureConverter.convertError(error, payloadConverter: self.payloadConverter)
                    self.stateMachine.workflowTaskFailed(temporalFailure: temporalFailure)
                }
            case .failure(let error):
                self.logger.trace("Workflow failed", metadata: [LoggingKeys.error: "\(error)"])
                await self.handleTopLevelError(error)
            }
        }
    }

    /// Applies the jobs of an activation.
    private func applyJobs<Workflow: WorkflowDefinition>(
        jobs: [Coresdk_WorkflowActivation_WorkflowActivationJob],
        workflow: WorkflowTaskExecutorIsolatedBox<Workflow>,
        workflowContext: WorkflowContext,
        group: inout ThrowingTaskGroup<Void, any Error>
    ) async {
        for job in jobs {
            switch job.variant {
            case .initializeWorkflow:
                // We can ignore this here since we are handling initialize separately
                break
            case .removeFromCache:
                // We can ignore this since it is handled at the worker level
                break
            case .cancelWorkflow:
                // We need to cancel the workflow's run method and all running handlers.
                // Cancelling is also modifying the state machine through continuations
                Self.$isOnWorkflowInstance.withValue(true) {
                    group.cancelAll()
                }
            case .updateRandomSeed(let updateRandomSeed):
                Self.$isOnWorkflowInstance.withValue(true) {
                    self.stateMachine.updateRandomnessSeed(updateRandomSeed.randomnessSeed)
                }
            case .notifyHasPatch(let notifyHasPatch):
                Self.$isOnWorkflowInstance.withValue(true) {
                    self.stateMachine.notifyHasPatch(notifyHasPatch)
                }
            case .fireTimer(let fireTimer):
                Self.$isOnWorkflowInstance.withValue(true) {
                    self.stateMachine.fireTimer(fireTimer)
                }
            case .resolveActivity(let resolveActivity):
                Self.$isOnWorkflowInstance.withValue(true) {
                    self.stateMachine.resolveActivity(resolveActivity)
                }
            case .resolveChildWorkflowExecutionStart(let resolveChildWorkflowExecutionStart):
                await Self.$isOnWorkflowInstance.withValue(true) {
                    await self.stateMachine.resolveStartChildWorkflow(resolveChildWorkflowExecutionStart)
                }
            case .resolveChildWorkflowExecution(let resolveChildWorkflowExecution):
                Self.$isOnWorkflowInstance.withValue(true) {
                    self.stateMachine.resolveChildWorkflowResult(
                        sequenceNumber: resolveChildWorkflowExecution.seq,
                        result: resolveChildWorkflowExecution.result
                    )
                }
            case .resolveSignalExternalWorkflow(let resolveSignalExternalWorkflow):
                await Self.$isOnWorkflowInstance.withValue(true) {
                    await self.stateMachine.resolveExternalWorkflowSignal(resolveSignalExternalWorkflow)
                }
            case .resolveRequestCancelExternalWorkflow:
                break
            case .queryWorkflow(let queryWorkflow):
                self.queryWorkflow(
                    queryWorkflow,
                    workflow: workflow,
                    workflowContext: workflowContext,
                    group: &group
                )
            case .signalWorkflow(let signalWorkflow):
                self.signalWorkflow(
                    signalWorkflow,
                    workflow: workflow,
                    workflowContext: workflowContext,
                    group: &group
                )
            case .doUpdate(let updateWorkflow):
                self.updateWorkflow(
                    updateWorkflow,
                    workflow: workflow,
                    workflowContext: workflowContext,
                    group: &group
                )
            case .resolveNexusOperation:
                break
            case .resolveNexusOperationStart:
                break
            case .none:
                break
            }
        }
    }

    /// Runs the executor until everything has yielded and all wait conditions have been processed.
    private func runExecutor(context: WorkflowContext) {
        while true {
            // 4.
            self.executor.run()
            // 5.
            // We are finding the first condition that evaluates to true and resume the associated
            // continuation. If we have resumed the first continuation then we are going to run the
            // executor again. This allows wait condition users to trust that the line after the
            // condition still has the condition satisfied.
            let continuationID = Self.$isOnWorkflowInstance.withValue(true) {
                Workflow.$context.withValue(context) {
                    self.stateMachine.conditions().first(where: { $0.value() })?.key
                }
            }
            guard let continuationID else {
                // We haven't found a single condition that evaluated to true so we are done with this
                // activation and can send all the generated commands.
                break
            }

            // 6.
            // We found our first condition that evaluates to true and are going to spin
            // the executor again.
            Self.$isOnWorkflowInstance.withValue(true) {
                self.stateMachine.resumeCondition(id: continuationID)
            }
        }
    }

    private func updateActivation(
        _ activation: Coresdk_WorkflowActivation_WorkflowActivation
    ) {
        Self.$isOnWorkflowInstance.withValue(true) {
            stateMachine.activate(with: activation)
        }
    }

    /// Completes the activation by sending the response to the worker.
    private func completeActivation(
        activation: Coresdk_WorkflowActivation_WorkflowActivation
    ) async throws {
        let commands = Self.$isOnWorkflowInstance.withValue(true) {
            self.stateMachine.commands()
        }
        switch commands {
        case .sendCommands(let commands):
            // The activation was applied successfully and the workflow's run method didn't end in
            // workflow task failure so we can report a successful activation completion.
            try await self.workflowWorkerCompleteWorkflowActivation(
                .with {
                    $0.runID = activation.runID
                    $0.status = .successful(
                        .with {
                            $0.commands = commands
                        }
                    )
                }
            )
        case .failActivation(let temporalFailure):
            try await self.workflowWorkerCompleteWorkflowActivation(
                .with {
                    $0.runID = activation.runID
                    $0.status = .failed(
                        .with {
                            $0.failure = .init(temporalFailure: temporalFailure)
                        }
                    )
                }
            )
        }
    }

    // MARK: Signals

    private func signalWorkflow<Workflow: WorkflowDefinition>(
        _ signalWorkflow: Coresdk_WorkflowActivation_SignalWorkflow,
        workflow: WorkflowTaskExecutorIsolatedBox<Workflow>,
        workflowContext: WorkflowContext,
        group: inout ThrowingTaskGroup<Void, any Error>
    ) {
        group.addTask(executorPreference: self.executor) {
            let workflow = workflow.wrapped
            guard let signal = Workflow.signals.first(where: { $0.name == signalWorkflow.signalName }) else {
                self.logger.error(
                    "No signal handler found",
                    metadata: [LoggingKeys.workflowSignalName: "\(signalWorkflow.signalName)"]
                )
                return
            }

            await self.runMessageHandler {
                await self.runSignal(
                    signal: signal,
                    workflow: workflow,
                    headers: signalWorkflow.headers.mapValues { TemporalPayload(temporalAPIPayload: $0) },
                    context: workflowContext,
                    temporalPayloads: signalWorkflow.input.map { .init(temporalAPIPayload: $0) }
                )
            }
        }
    }

    private func runSignal<Signal: WorkflowSignalDefinition>(
        signal: Signal,
        workflow: Signal.Workflow,
        headers: [String: TemporalPayload],
        context: WorkflowContext,
        temporalPayloads: [TemporalPayload]
    ) async {
        let input: Signal.Input
        do {
            input = try self.payloadConverter.convertPayloads(temporalPayloads, as: Signal.Input.self)
        } catch {
            self.logger.error(
                "Failed converting signal input",
                metadata: [
                    LoggingKeys.workflowSignalName: "\(Signal.name)",
                    LoggingKeys.error: "\(error)",
                ]
            )
            return
        }

        do {
            self.logger.trace("Running signal handler")
            try await implementation.handleSignal(
                workflow: workflow,
                context: context,
                input: .init(
                    name: signal.name,
                    definition: signal,
                    headers: headers,
                    input: input
                )
            )
            self.logger.trace("Running signal handler finished")
        } catch {
            // Signal handlers are treated as top level code i.e. they are
            // on the same level as the workflows primary run method. This means
            // that a throwing signal in a workflow has the same effect as a throwing
            // workflow run method.
            self.logger.trace("Running signal handler failed", metadata: [LoggingKeys.error: "\(error)"])
            await self.handleTopLevelError(error)
        }
    }

    // MARK: Queries

    private func queryWorkflow<Workflow: WorkflowDefinition>(
        _ queryWorkflow: Coresdk_WorkflowActivation_QueryWorkflow,
        workflow: WorkflowTaskExecutorIsolatedBox<Workflow>,
        workflowContext: WorkflowContext,
        group: inout ThrowingTaskGroup<Void, any Error>
    ) {
        group.addTask(executorPreference: self.executor) {
            let workflow = workflow.wrapped
            if queryWorkflow.queryType == "__temporal_workflow_metadata" {
                await self.runMessageHandler {
                    do {
                        let metadata = workflowMetadata(type: Workflow.self, context: workflowContext)
                        // Use the default data converter as this query will be
                        // used for displaying information in the Temporal UI.
                        let payload = try await DataConverter.default.convertValue(metadata)
                        self.stateMachine.queryFinished(id: queryWorkflow.queryID, temporalPayload: payload)
                    } catch {
                        self.logger.trace(
                            "Running query handler failed",
                            metadata: [
                                LoggingKeys.workflowQueryID: "\(queryWorkflow.queryID)",
                                LoggingKeys.workflowQueryName: "\(queryWorkflow.queryType)",
                                LoggingKeys.error: "\(error)",
                            ]
                        )
                        let temporalFailure = self.failureConverter.convertError(error, payloadConverter: self.payloadConverter)
                        self.stateMachine.queryFailed(id: queryWorkflow.queryID, temporalFailure: temporalFailure)
                    }
                }
                return
            }

            guard let query = Workflow.queries.first(where: { $0.name == queryWorkflow.queryType }) else {
                self.logger.error(
                    "No query handler found",
                    metadata: [LoggingKeys.workflowQueryName: "\(queryWorkflow.queryType)"]
                )
                // If we fail to find a handler we treat it as a workflow task failure
                // so that the workflow will get retried and a new code deploy can fix the issue.
                self.stateMachine.workflowTaskFailed(
                    temporalFailure: .init(
                        message:
                            "Query handler for \(queryWorkflow.queryType) expected but not found, known queries: [\(Workflow.queries.lazy.map { $0.name }.sorted().joined(separator: ","))",
                        source: "swift-temporal-sdk",
                        stackTrace: ""
                    )
                )
                return
            }

            await self.runMessageHandler {
                await self.runQuery(
                    id: queryWorkflow.queryID,
                    query: query,
                    workflow: workflow,
                    context: workflowContext,
                    headers: queryWorkflow.headers.mapValues { TemporalPayload(temporalAPIPayload: $0) },
                    temporalPayloads: queryWorkflow.arguments.map { .init(temporalAPIPayload: $0) }
                )
            }
        }
    }

    private func runQuery<Query: WorkflowQueryDefinition, Workflow: WorkflowDefinition>(
        id: String,
        query: Query,
        workflow: Workflow,
        context: WorkflowContext,
        headers: [String: TemporalPayload],
        temporalPayloads: [TemporalPayload]
    ) async where Query.Workflow == Workflow {
        let input: Query.Input
        do {
            input = try self.payloadConverter.convertPayloads(temporalPayloads, as: Query.Input.self)
        } catch {
            self.logger.error(
                "Failed converting query input",
                metadata: [
                    LoggingKeys.workflowQueryID: "\(id)",
                    LoggingKeys.workflowQueryName: "\(Query.name)",
                    LoggingKeys.error: "\(error)",
                ]
            )
            return
        }

        do {
            self.logger.trace(
                "Running query handler",
                metadata: [
                    LoggingKeys.workflowQueryID: "\(id)",
                    LoggingKeys.workflowQueryName: "\(Query.name)",
                ]
            )
            let output = try Self.$isWorkflowStateFrozen.withValue(true) {
                // Context is frozen during query execution to prevent side effects
                try implementation.handleQuery(
                    workflow: workflow,
                    context: context,
                    input: .init(
                        id: id,
                        name: Query.name,
                        definition: query,
                        headers: headers,
                        input: input
                    )
                )
            }
            self.logger.trace(
                "Running query handler finished",
                metadata: [
                    LoggingKeys.workflowQueryID: "\(id)",
                    LoggingKeys.workflowQueryName: "\(Query.name)",
                ]
            )
            let payload = try self.payloadConverter.convertValueHandlingVoid(output)
            self.stateMachine.queryFinished(id: id, temporalPayload: payload)
        } catch {
            self.logger.trace(
                "Running query handler failed",
                metadata: [
                    LoggingKeys.workflowQueryID: "\(id)",
                    LoggingKeys.workflowQueryName: "\(Query.name)",
                    LoggingKeys.error: "\(error)",
                ]
            )
            let temporalFailure = self.failureConverter.convertError(error, payloadConverter: self.payloadConverter)
            self.stateMachine.queryFailed(id: id, temporalFailure: temporalFailure)
        }
    }

    private func workflowMetadata<Workflow: WorkflowDefinition>(
        type: Workflow.Type,
        context: WorkflowContext
    ) -> Temporal_Api_Sdk_V1_WorkflowMetadata {
        var definition = Temporal_Api_Sdk_V1_WorkflowDefinition.with {
            $0.type = context.info.workflowType
        }

        definition.queryDefinitions = type.queries.lazy.map { query in
            .with {
                $0.name = query.name
                if let description = query.description {
                    $0.description_p = description
                }
            }
        }
        .sorted { $0.name < $1.name }

        definition.signalDefinitions = type.signals.lazy.map { signal in
            .with {
                $0.name = signal.name
                if let description = signal.description {
                    $0.description_p = description
                }
            }
        }
        .sorted { $0.name < $1.name }

        definition.updateDefinitions = type.updates.lazy.map { update in
            .with {
                $0.name = update.name
                if let description = update.description {
                    $0.description_p = description
                }
            }
        }
        .sorted { $0.name < $1.name }

        return .with {
            $0.definition = definition
            if let currentDetails = context.currentDetails {
                $0.currentDetails = currentDetails
            }
        }
    }

    // MARK: Updates

    private func updateWorkflow<Workflow: WorkflowDefinition>(
        _ updateWorkflow: Coresdk_WorkflowActivation_DoUpdate,
        workflow: WorkflowTaskExecutorIsolatedBox<Workflow>,
        workflowContext: WorkflowContext,
        group: inout ThrowingTaskGroup<Void, any Error>
    ) {
        group.addTask(executorPreference: self.executor) {
            let workflow = workflow.wrapped
            guard let update = Workflow.updates.first(where: { $0.name == updateWorkflow.name }) else {
                self.logger.error(
                    "No update handler found",
                    metadata: [LoggingKeys.workflowQueryName: "\(updateWorkflow.name)"]
                )
                // If we fail to find a handler we treat it as a workflow task failure
                // so that the workflow will get retried and a new code deploy can fix the issue.
                self.stateMachine.workflowTaskFailed(
                    temporalFailure: .init(
                        message:
                            "Update handler for \(updateWorkflow.name) expected but not found, known updates: [\(Workflow.updates.lazy.map { $0.name }.sorted().joined(separator: ","))",
                        source: "swift-temporal-sdk",
                        stackTrace: ""
                    )
                )
                return
            }

            await self.runMessageHandler {
                await self.runUpdate(
                    id: updateWorkflow.protocolInstanceID,
                    runValidator: updateWorkflow.runValidator,
                    update: update,
                    workflow: workflow,
                    workflowContext: workflowContext,
                    headers: updateWorkflow.headers.mapValues { TemporalPayload(temporalAPIPayload: $0) },
                    temporalPayloads: updateWorkflow.input.map { .init(temporalAPIPayload: $0) }
                )
            }
        }
    }

    private func runUpdate<Update: WorkflowUpdateDefinition, Workflow: WorkflowDefinition>(
        id: String,
        runValidator: Bool,
        update: Update,
        workflow: Workflow,
        workflowContext: WorkflowContext,
        headers: [String: TemporalPayload],
        temporalPayloads: [TemporalPayload]
    ) async where Update.Workflow == Workflow {
        // The input is given to both the validator method and the update method to match
        // other temporal SDKs we are passing two separately converted inputs to disallow
        // user mutation of the input between validator and update.
        // Define this here since we will perform this operation multiple times.
        func convertInput() -> Update.Input? {
            do {
                return try self.payloadConverter.convertPayloads(temporalPayloads, as: Update.Input.self)
            } catch {
                self.logger.error(
                    "Failed converting update input",
                    metadata: [
                        LoggingKeys.workflowUpdateID: "\(id)",
                        LoggingKeys.workflowUpdateName: "\(Update.name)",
                        LoggingKeys.error: "\(error)",
                    ]
                )

                // Tell Temporal that we are rejecting the update because we aren't able to decode the input.
                self.stateMachine.updateRejected(
                    id: id,
                    temporalFailure: self.failureConverter.convertError(error, payloadConverter: self.payloadConverter)
                )
                return nil
            }
        }

        if runValidator {
            do {
                guard let validatorInput = convertInput() else {
                    return
                }

                try Self.$isWorkflowStateFrozen.withValue(true) {
                    // Context is frozen during update validation to prevent side effects
                    try implementation.validateUpdate(
                        context: workflowContext,
                        input: .init(
                            id: id,
                            name: Update.name,
                            definition: update,
                            headers: headers,
                            input: validatorInput
                        )
                    )
                }
            } catch {
                self.logger.debug(
                    "Update rejected",
                    metadata: [
                        LoggingKeys.workflowUpdateID: "\(id)",
                        LoggingKeys.workflowUpdateName: "\(Update.name)",
                        LoggingKeys.error: "\(error)",
                    ]
                )
                let temporalFailure = self.failureConverter.convertError(error, payloadConverter: self.payloadConverter)
                self.stateMachine.updateRejected(id: id, temporalFailure: temporalFailure)
            }
        }

        guard let updateInput = convertInput() else {
            return
        }

        // The validator passed and our data conversion for the inputs succeeded.
        // Time to tell Temporal that we accept the update.
        self.stateMachine.updateAccepted(id: id)

        do {
            self.logger.trace(
                "Running update handler",
                metadata: [
                    LoggingKeys.workflowUpdateID: "\(id)",
                    LoggingKeys.workflowUpdateName: "\(Update.name)",
                ]
            )
            let output = try await implementation.handleUpdate(
                workflow: workflow,
                context: workflowContext,
                input: .init(
                    id: id,
                    name: Update.name,
                    definition: update,
                    headers: headers,
                    input: updateInput
                )
            )
            self.logger.trace(
                "Running update handler finished",
                metadata: [
                    LoggingKeys.workflowUpdateID: "\(id)",
                    LoggingKeys.workflowUpdateName: "\(Update.name)",
                ]
            )
            let payload = try self.payloadConverter.convertValueHandlingVoid(output)
            self.stateMachine.updateCompleted(id: id, temporalPayload: payload)
        } catch {
            self.logger.trace(
                "Running update handler failed",
                metadata: [
                    LoggingKeys.workflowUpdateID: "\(id)",
                    LoggingKeys.workflowUpdateName: "\(Update.name)",
                    LoggingKeys.error: "\(error)",
                ]
            )
            // Similar to errors thrown from the workflow's run method, errors thrown from
            // update handlers can lead to either update rejection or workflow task failure.
            // The categorization is identical to workflow's run method errors in that it depends
            // if it is a TemporalFailureError or not.
            // Updates have 5 states: admitted (reached server but not worker), accepted (validated but not
            // complete), rejected (failed validation), success, and failure.
            // Core just combines rejection (i.e. during validation) and failure (i.e. after validation) into the
            // same field in the proto and calls it "rejection".
            if let temporalFailureError = error as? TemporalFailureError {
                let temporalFailure = self.failureConverter.convertError(temporalFailureError, payloadConverter: self.payloadConverter)
                self.stateMachine.updateRejected(id: id, temporalFailure: temporalFailure)
            } else {
                let temporalFailure = self.failureConverter.convertError(error, payloadConverter: self.payloadConverter)
                self.stateMachine.workflowTaskFailed(temporalFailure: temporalFailure)
            }
        }
    }

    // MARK: Handlers

    private func runMessageHandler(body: () async -> Void) async {
        self.stateMachine.handlerStarted()
        await body()
        self.stateMachine.handlerFinished()
    }

    // MARK: Top level error handling

    private func handleTopLevelError(_ error: any Error) async {
        if let continueAsNewError = error as? ContinueAsNewError {
            self.logger.debug("Workflow requested continue as new")
            self.stateMachine.continueAsNew(continueAsNewError)
        } else if let temporalFailureError = error as? TemporalFailureError {
            // If the thrown error is a temporal failure error it needs to fail the whole
            // workflow.
            let temporalFailure = self.failureConverter.convertError(temporalFailureError, payloadConverter: self.payloadConverter)
            self.stateMachine.workflowFinished(temporalFailure: temporalFailure)
        } else {
            // If it's any other error type we need to fail the activation
            // so that the workflow task can be retried
            let temporalFailure = self.failureConverter.convertError(error, payloadConverter: self.payloadConverter)
            self.stateMachine.workflowTaskFailed(temporalFailure: temporalFailure)
        }
    }
}

extension WorkflowInstance {
    struct Implementation: InterceptorImplementation {
        let interceptors: [any WorkflowInboundInterceptor]
    }
}

extension WorkflowInstance.Implementation {
    func executeWorkflow<Workflow: WorkflowDefinition>(
        workflow: Workflow,
        context: WorkflowContext,
        input: ExecuteWorkflowInput<Workflow>
    ) async throws -> Workflow.Output {
        try await Temporal.Workflow.$context.withValue(context) {
            try await WorkflowInstance.$isWorkflowStateFrozen.withValue(true) {
                try await intercept(WorkflowInboundInterceptor.executeWorkflow, input: input) { input in
                    try await WorkflowInstance.$isWorkflowStateFrozen.withValue(false) {
                        try await workflow.run(input: input.input)
                    }
                }
            }
        }
    }

    func handleSignal<Signal: WorkflowSignalDefinition>(
        workflow: Signal.Workflow,
        context: WorkflowContext,
        input: HandleSignalInput<Signal>
    ) async throws {
        try await Temporal.Workflow.$context.withValue(context) {
            try await WorkflowInstance.$isWorkflowStateFrozen.withValue(true) {
                try await intercept(WorkflowInboundInterceptor.handleSignal, input: input) { input in
                    try await WorkflowInstance.$isWorkflowStateFrozen.withValue(false) {
                        try await input.definition.run(
                            workflow: workflow,
                            input: input.input
                        )
                    }
                }
            }
        }
    }

    func handleQuery<Query: WorkflowQueryDefinition>(
        workflow: Query.Workflow,
        context: WorkflowContext,
        input: HandleQueryInput<Query>
    ) throws -> Query.Output {
        try Temporal.Workflow.$context.withValue(context) {
            try WorkflowInstance.$isWorkflowStateFrozen.withValue(true) {
                try intercept(WorkflowInboundInterceptor.handleQuery, input: input) { input in
                    try WorkflowInstance.$isWorkflowStateFrozen.withValue(false) {
                        try input.definition.run(
                            workflow: workflow,
                            input: input.input
                        )
                    }
                }
            }
        }
    }

    func handleUpdate<Update: WorkflowUpdateDefinition>(
        workflow: Update.Workflow,
        context: WorkflowContext,
        input: HandleUpdateInput<Update>
    ) async throws -> Update.Output {
        try await Temporal.Workflow.$context.withValue(context) {
            try await WorkflowInstance.$isWorkflowStateFrozen.withValue(true) {
                try await intercept(WorkflowInboundInterceptor.handleUpdate, input: input) { input in
                    try await WorkflowInstance.$isWorkflowStateFrozen.withValue(false) {
                        try await input.definition.run(
                            workflow: workflow,
                            input: input.input
                        )
                    }
                }
            }
        }
    }

    func validateUpdate<Update: WorkflowUpdateDefinition>(
        context: WorkflowContext,
        input: HandleUpdateInput<Update>
    ) throws {
        try Temporal.Workflow.$context.withValue(context) {
            try WorkflowInstance.$isWorkflowStateFrozen.withValue(true) {
                try intercept(WorkflowInboundInterceptor.validateUpdate, input: input) { input in
                    try WorkflowInstance.$isWorkflowStateFrozen.withValue(false) {
                        try input.definition.validateInput(input.input)
                    }
                }
            }
        }
    }
}
