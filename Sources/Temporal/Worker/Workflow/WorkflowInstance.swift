//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Temporal SDK open source project
//
// Copyright (c) 2025 Apple Inc. and the Swift Temporal SDK project authors
// Licensed under MIT License
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Swift Temporal SDK project authors
//
// SPDX-License-Identifier: MIT
//
//===----------------------------------------------------------------------===//

import Logging
import SwiftProtobuf

/// A workflow runner is responsible for handling a single instance of a workflow.
///
/// This type processes new workflow activations, handles the workflow's executor and sends any outbound commands.
struct WorkflowInstance: Sendable {
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
            _ completion: consuming Coresdk.WorkflowCompletion.WorkflowActivationCompletion
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
        var inboundInterceptors = [any WorkflowInboundInterceptor]()
        var outboundInterceptors = [any WorkflowOutboundInterceptor]()
        for interceptor in workflowWorker.interceptors {
            if let inbound = interceptor.workflowInboundInterceptor {
                inboundInterceptors.append(inbound)
            }
            if let outbound = interceptor.workflowOutboundInterceptor {
                outboundInterceptors.append(outbound)
            }
        }
        self.implementation = .init(interceptors: inboundInterceptors, executor: self.executor)
        self.outboundInterceptors = outboundInterceptors
        self.logger = logger
    }

    func run<Workflow: WorkflowDefinition>(
        workflowType: Workflow.Type,
        activations: some AsyncSequence<Coresdk.WorkflowActivation.WorkflowActivation, Never>
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
        let workflowStateBox: ArcBox<Workflow>
        let input: WorkflowTaskExecutorIsolatedBox<Workflow.Input>
        let workflowContext: InternalWorkflowContext
        let publicContext: WorkflowContext<Workflow>
        do {
            (workflowStateBox, input, workflowContext, publicContext) = try await self.initializeWorkflow(
                activation,
                workflowType: workflowType
            )
        } catch {
            // We failed to initialize the workflow. This indicates a workflow task failure
            // so let's fail the activation and return here.
            let failure = self.failureConverter.convertError(
                error,
                payloadConverter: self.payloadConverter
            )
            try await self.workflowWorkerCompleteWorkflowActivation(
                .with {
                    $0.runID = activation.runID
                    $0.status = .failed(
                        .with {
                            $0.failure = failure
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
                workflowStateBox: workflowStateBox,
                workflowContext: workflowContext,
                publicContext: publicContext,
                group: &group
            )

            // 3.
            self.startWorkflow(
                workflowStateBox: workflowStateBox,
                input: input,
                workflowContext: workflowContext,
                publicContext: publicContext,
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
                    workflowStateBox: workflowStateBox,
                    workflowContext: workflowContext,
                    publicContext: publicContext,
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
            // when replaying for a query). We can't leave a dangling cancellation
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
        _ activation: Coresdk.WorkflowActivation.WorkflowActivation,
        workflowType: Workflow.Type
    ) async throws -> (ArcBox<Workflow>, WorkflowTaskExecutorIsolatedBox<Workflow.Input>, InternalWorkflowContext, WorkflowContext<Workflow>) {
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
                initializeWorkflow.arguments,
                as: (Workflow.Input).self
            )
        }

        // Initially setting memo, search attributes and random seed.
        try Self.$isOnWorkflowInstance.withValue(true) {
            self.stateMachine.setMemo(initializeWorkflow.memo.fields.mapValues { .init($0) })
            self.stateMachine.setSearchAttributes(try .init(initializeWorkflow.searchAttributes))
            self.stateMachine.updateRandomnessSeed(initializeWorkflow.randomnessSeed)
        }

        let workflowContext = InternalWorkflowContext(
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

        let workflowStateBox = ArcBox(Workflow(input: input))
        let inputBox = WorkflowTaskExecutorIsolatedBox(
            executor: self.executor,
            wrapped: input
        )
        let publicContext = WorkflowContext(
            internalContext: workflowContext,
            stateBox: workflowStateBox
        )
        return (workflowStateBox, inputBox, workflowContext, publicContext)
    }

    // Starts the workflows run method in a separate child task
    private func startWorkflow<Workflow: WorkflowDefinition>(
        workflowStateBox: ArcBox<Workflow>,
        input: WorkflowTaskExecutorIsolatedBox<Workflow.Input>,
        workflowContext: InternalWorkflowContext,
        publicContext: WorkflowContext<Workflow>,
        group: inout ThrowingTaskGroup<Void, any Error>
    ) {
        group.addTask(executorPreference: self.executor) {
            self.logger.trace("Intercepting workflow")
            let workflow = workflowStateBox.value
            let workflowResult = await Result {
                // Context is not frozen during normal workflow execution
                try await self.implementation.executeWorkflow(
                    workflow: workflow,
                    context: workflowContext,
                    publicContext: publicContext,
                    input: .init(
                        info: workflowContext.info,
                        headers: workflowContext.info.headers,
                        input: input.wrapped
                    )
                )
            }

            // Warn about unfinished handlers when the workflow completes and we are
            // not replaying (to avoid duplicate warnings during replay).
            self.warnUnfinishedHandlers()

            switch workflowResult {
            case .success(let output):
                self.logger.trace("Workflow finished")
                let dataConversionResult = await Result { () async throws -> Api.Common.V1.Payload in
                    try self.payloadConverter.convertValueHandlingVoid(output)
                }
                switch dataConversionResult {
                case .success(let temporalPayload):
                    self.stateMachine.workflowFinished(temporalPayload: temporalPayload)
                case .failure(let error):
                    let failure = self.failureConverter.convertError(error, payloadConverter: self.payloadConverter)
                    self.stateMachine.workflowTaskFailed(failure: failure)
                }
            case .failure(let error):
                self.logger.trace(
                    "Workflow failed",
                    metadata: [
                        LoggingKeys.errorType: "\(type(of: error))",
                        LoggingKeys.errorMessage: "\(error)",
                    ]
                )
                await self.handleTopLevelError(error)
            }
        }
    }

    /// Applies the jobs of an activation.
    private func applyJobs<Workflow: WorkflowDefinition>(
        jobs: [Coresdk.WorkflowActivation.WorkflowActivationJob],
        workflowStateBox: ArcBox<Workflow>,
        workflowContext: InternalWorkflowContext,
        publicContext: WorkflowContext<Workflow>,
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
            case .resolveRequestCancelExternalWorkflow(let resolveRequestCancelExternalWorkflow):
                await Self.$isOnWorkflowInstance.withValue(true) {
                    await self.stateMachine.resolveRequestCancelExternalWorkflow(resolveRequestCancelExternalWorkflow)
                }
            case .queryWorkflow(let queryWorkflow):
                self.queryWorkflow(
                    queryWorkflow,
                    workflowStateBox: workflowStateBox,
                    workflowContext: workflowContext,
                    group: &group
                )
            case .signalWorkflow(let signalWorkflow):
                self.signalWorkflow(
                    signalWorkflow,
                    workflowStateBox: workflowStateBox,
                    workflowContext: workflowContext,
                    publicContext: publicContext,
                    group: &group
                )
            case .doUpdate(let updateWorkflow):
                self.updateWorkflow(
                    updateWorkflow,
                    workflowStateBox: workflowStateBox,
                    workflowContext: workflowContext,
                    publicContext: publicContext,
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
    private func runExecutor(context: InternalWorkflowContext) {
        while true {
            // 4.
            self.executor.run()
            // 5.
            // We are finding the first condition that evaluates to true and resume the associated
            // continuation. If we have resumed the first continuation then we are going to run the
            // executor again. This allows wait condition users to trust that the line after the
            // condition still has the condition satisfied.
            let continuationID = Self.$isOnWorkflowInstance.withValue(true) {
                InternalWorkflowContext.$current.withValue(context) {
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
        _ activation: Coresdk.WorkflowActivation.WorkflowActivation
    ) {
        Self.$isOnWorkflowInstance.withValue(true) {
            stateMachine.activate(with: activation)
        }
    }

    /// Completes the activation by sending the response to the worker.
    private func completeActivation(
        activation: Coresdk.WorkflowActivation.WorkflowActivation
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
        case .failActivation(let failure):
            try await self.workflowWorkerCompleteWorkflowActivation(
                .with {
                    $0.runID = activation.runID
                    $0.status = .failed(
                        .with {
                            $0.failure = failure
                        }
                    )
                }
            )
        }
    }

    // MARK: Signals

    private func signalWorkflow<Workflow: WorkflowDefinition>(
        _ signalWorkflow: Coresdk.WorkflowActivation.SignalWorkflow,
        workflowStateBox: ArcBox<Workflow>,
        workflowContext: InternalWorkflowContext,
        publicContext: WorkflowContext<Workflow>,
        group: inout ThrowingTaskGroup<Void, any Error>
    ) {
        group.addTask(executorPreference: self.executor) {
            let workflow = workflowStateBox.value
            guard let signal = Workflow.signals.first(where: { $0.name == signalWorkflow.signalName }) else {
                self.logger.error(
                    "No signal handler found",
                    metadata: [LoggingKeys.workflowSignalName: "\(signalWorkflow.signalName)"]
                )
                return
            }

            await self.runMessageHandler(
                name: signal.name,
                updateId: nil,
                unfinishedPolicy: signal.unfinishedPolicy
            ) {
                await self.runSignal(
                    signal: signal,
                    workflow: workflow,
                    headers: signalWorkflow.headers,
                    context: workflowContext,
                    publicContext: publicContext,
                    temporalPayloads: signalWorkflow.input
                )
            }
        }
    }

    private func runSignal<Signal: WorkflowSignalDefinition>(
        signal: Signal,
        workflow: Signal.Workflow,
        headers: [String: Api.Common.V1.Payload],
        context: InternalWorkflowContext,
        publicContext: WorkflowContext<Signal.Workflow>,
        temporalPayloads: [Api.Common.V1.Payload]
    ) async {
        let input: Signal.Input
        do {
            input = try self.payloadConverter.convertPayloads(temporalPayloads, as: Signal.Input.self)
        } catch {
            self.logger.error(
                "Failed converting signal input",
                metadata: [
                    LoggingKeys.workflowSignalName: "\(Signal.name)",
                    LoggingKeys.errorType: "\(type(of: error))",
                    LoggingKeys.errorMessage: "\(error)",
                ]
            )
            return
        }

        do {
            self.logger.trace("Running signal handler")
            try await implementation.handleSignal(
                workflow: workflow,
                context: context,
                publicContext: publicContext,
                input: .init(
                    info: context.info,
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
            self.logger.trace(
                "Running signal handler failed",
                metadata: [
                    LoggingKeys.errorType: "\(type(of: error))",
                    LoggingKeys.errorMessage: "\(error)",
                ]
            )
            await self.handleTopLevelError(error)
        }
    }

    // MARK: Queries

    private func queryWorkflow<Workflow: WorkflowDefinition>(
        _ queryWorkflow: Coresdk.WorkflowActivation.QueryWorkflow,
        workflowStateBox: ArcBox<Workflow>,
        workflowContext: InternalWorkflowContext,
        group: inout ThrowingTaskGroup<Void, any Error>
    ) {
        group.addTask(executorPreference: self.executor) {
            let workflow = workflowStateBox.value
            if queryWorkflow.queryType == "__temporal_workflow_metadata" {
                await self.runMessageHandler(
                    name: queryWorkflow.queryType,
                    updateId: nil,
                    unfinishedPolicy: .abandon
                ) {
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
                                LoggingKeys.errorType: "\(type(of: error))",
                                LoggingKeys.errorMessage: "\(error)",
                            ]
                        )
                        let failure = self.failureConverter.convertError(error, payloadConverter: self.payloadConverter)
                        self.stateMachine.queryFailed(id: queryWorkflow.queryID, failure: failure)
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
                    failure: .with {
                        $0.message =
                            "Query handler for \(queryWorkflow.queryType) expected but not found, known queries: [\(Workflow.queries.lazy.map { $0.name }.sorted().joined(separator: ","))"
                        $0.source = "swift-temporal-sdk"
                    }
                )
                return
            }

            await self.runMessageHandler(
                name: query.name,
                updateId: nil,
                unfinishedPolicy: .abandon
            ) {
                await self.runQuery(
                    id: queryWorkflow.queryID,
                    query: query,
                    workflow: workflow,
                    context: workflowContext,
                    headers: queryWorkflow.headers,
                    temporalPayloads: queryWorkflow.arguments
                )
            }
        }
    }

    private func runQuery<Query: WorkflowQueryDefinition, Workflow: WorkflowDefinition>(
        id: String,
        query: Query,
        workflow: Workflow,
        context: InternalWorkflowContext,
        headers: [String: Api.Common.V1.Payload],
        temporalPayloads: [Api.Common.V1.Payload]
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
                    LoggingKeys.errorType: "\(type(of: error))",
                    LoggingKeys.errorMessage: "\(error)",
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
            let output = try implementation.handleQuery(
                workflow: workflow,
                context: context,
                input: .init(
                    info: context.info,
                    id: id,
                    name: Query.name,
                    definition: query,
                    headers: headers,
                    input: input
                )
            )
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
                    LoggingKeys.errorType: "\(type(of: error))",
                    LoggingKeys.errorMessage: "\(error)",
                ]
            )
            let failure = self.failureConverter.convertError(error, payloadConverter: self.payloadConverter)
            self.stateMachine.queryFailed(id: id, failure: failure)
        }
    }

    private func workflowMetadata<Workflow: WorkflowDefinition>(
        type: Workflow.Type,
        context: InternalWorkflowContext
    ) -> Api.Sdk.V1.WorkflowMetadata {
        var definition = Api.Sdk.V1.WorkflowDefinition.with {
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
        _ updateWorkflow: Coresdk.WorkflowActivation.DoUpdate,
        workflowStateBox: ArcBox<Workflow>,
        workflowContext: InternalWorkflowContext,
        publicContext: WorkflowContext<Workflow>,
        group: inout ThrowingTaskGroup<Void, any Error>
    ) {
        group.addTask(executorPreference: self.executor) {
            let workflow = workflowStateBox.value
            guard let update = Workflow.updates.first(where: { $0.name == updateWorkflow.name }) else {
                self.logger.error(
                    "No update handler found",
                    metadata: [LoggingKeys.workflowQueryName: "\(updateWorkflow.name)"]
                )
                // If we fail to find a handler we treat it as a workflow task failure
                // so that the workflow will get retried and a new code deploy can fix the issue.
                self.stateMachine.workflowTaskFailed(
                    failure: .with {
                        $0.message =
                            "Update handler for \(updateWorkflow.name) expected but not found, known updates: [\(Workflow.updates.lazy.map { $0.name }.sorted().joined(separator: ","))"
                        $0.source = "swift-temporal-sdk"
                    }
                )
                return
            }

            await self.runMessageHandler(
                name: update.name,
                updateId: updateWorkflow.protocolInstanceID,
                unfinishedPolicy: update.unfinishedPolicy
            ) {
                await self.runUpdate(
                    id: updateWorkflow.protocolInstanceID,
                    runValidator: updateWorkflow.runValidator,
                    update: update,
                    workflow: workflow,
                    workflowContext: workflowContext,
                    publicContext: publicContext,
                    headers: updateWorkflow.headers,
                    temporalPayloads: updateWorkflow.input
                )
            }
        }
    }

    private func runUpdate<Update: WorkflowUpdateDefinition, Workflow: WorkflowDefinition>(
        id: String,
        runValidator: Bool,
        update: Update,
        workflow: Workflow,
        workflowContext: InternalWorkflowContext,
        publicContext: WorkflowContext<Workflow>,
        headers: [String: Api.Common.V1.Payload],
        temporalPayloads: [Api.Common.V1.Payload]
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
                        LoggingKeys.errorType: "\(type(of: error))",
                        LoggingKeys.errorMessage: "\(error)",
                    ]
                )

                // Tell Temporal that we are rejecting the update because we aren't able to decode the input.
                self.stateMachine.updateRejected(
                    id: id,
                    failure: self.failureConverter.convertError(error, payloadConverter: self.payloadConverter)
                )
                return nil
            }
        }

        if runValidator {
            do {
                guard let validatorInput = convertInput() else {
                    return
                }

                try implementation.validateUpdate(
                    workflow: workflow,
                    context: workflowContext,
                    input: .init(
                        info: workflowContext.info,
                        id: id,
                        name: Update.name,
                        definition: update,
                        headers: headers,
                        input: validatorInput
                    )
                )
            } catch {
                self.logger.debug(
                    "Update rejected",
                    metadata: [
                        LoggingKeys.workflowUpdateID: "\(id)",
                        LoggingKeys.workflowUpdateName: "\(Update.name)",
                        LoggingKeys.errorType: "\(type(of: error))",
                        LoggingKeys.errorMessage: "\(error)",
                    ]
                )
                let failure = self.failureConverter.convertError(error, payloadConverter: self.payloadConverter)
                self.stateMachine.updateRejected(id: id, failure: failure)
                return
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
                publicContext: publicContext,
                input: .init(
                    info: workflowContext.info,
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
                    LoggingKeys.errorType: "\(type(of: error))",
                    LoggingKeys.errorMessage: "\(error)",
                ]
            )
            // Similar to errors thrown from the workflow's run method, errors thrown from
            // update handlers can lead to either update rejection or workflow task failure.
            // The categorization is identical to workflow's run method errors in that it depends
            // if it is a Api.Failure.V1.FailureError or not.
            // Updates have 5 states: admitted (reached server but not worker), accepted (validated but not
            // complete), rejected (failed validation), success, and failure.
            // Core just combines rejection (i.e. during validation) and failure (i.e. after validation) into the
            // same field in the proto and calls it "rejection".
            if let temporalFailureError = error as? any TemporalFailureError {
                let failure = self.failureConverter.convertError(temporalFailureError, payloadConverter: self.payloadConverter)
                self.stateMachine.updateRejected(id: id, failure: failure)
            } else {
                let failure = self.failureConverter.convertError(error, payloadConverter: self.payloadConverter)
                self.stateMachine.workflowTaskFailed(failure: failure)
            }
        }
    }

    // MARK: Handlers

    /// Logs a warning if there are still running handlers with the ``HandlerUnfinishedPolicy/warnAndAbandon`` policy
    /// when the workflow's run method completes.
    private func warnUnfinishedHandlers() {
        let isReplaying = Self.$isOnWorkflowInstance.withValue(true) {
            self.stateMachine.isReplaying()
        }
        guard !isReplaying else { return }

        let warnEntries = Self.$isOnWorkflowInstance.withValue(true) {
            self.stateMachine.unfinishedWarnHandlerEntries()
        }
        guard !warnEntries.isEmpty else { return }

        // Separate signals (updateId == nil) from updates (updateId != nil)
        let signalEntries = warnEntries.filter { $0.updateId == nil }
        let updateEntries = warnEntries.filter { $0.updateId != nil }

        // Build metadata
        var metadata: Logger.Metadata = [:]

        if !signalEntries.isEmpty {
            var signalCounts: [String: Int] = [:]
            for entry in signalEntries {
                signalCounts[entry.name, default: 0] += 1
            }
            let signalParts =
                signalCounts
                .sorted(by: { $0.key < $1.key })
                .map { "{\"name\":\"\($0.key)\",\"count\":\($0.value)}" }
            metadata[LoggingKeys.unfinishedSignalHandlers] = "[\(signalParts.joined(separator: ","))]"
        }

        if !updateEntries.isEmpty {
            let updateParts =
                updateEntries
                .sorted(by: { $0.name < $1.name })
                .map { "{\"name\":\"\($0.name)\",\"id\":\"\($0.updateId ?? "")\"}" }
            metadata[LoggingKeys.unfinishedUpdateHandlers] = "[\(updateParts.joined(separator: ","))]"
        }

        let message: Logger.Message =
            """
            Workflow finished while signal or update handlers are still running. \
            This may have interrupted work that a handler was doing, and the client that sent the \
            update may receive a 'workflow execution already completed' error. \
            You can wait for all handlers to finish by using \
            `try await Workflow.condition { Workflow.allHandlersFinished }`. \
            Alternatively, to suppress this warning for a specific handler, set its unfinished \
            policy to `.abandon`, for example: \
            `@WorkflowSignal(unfinishedPolicy: .abandon)`.
            """

        self.logger.info(message, metadata: metadata)
    }

    private func runMessageHandler(
        name: String,
        updateId: String?,
        unfinishedPolicy: HandlerUnfinishedPolicy,
        body: () async -> Void
    ) async {
        self.stateMachine.handlerStarted(name: name, updateId: updateId, unfinishedPolicy: unfinishedPolicy)
        await body()
        self.stateMachine.handlerFinished(name: name, updateId: updateId)
    }

    // MARK: Top level error handling

    private func handleTopLevelError(_ error: any Error) async {
        if let continueAsNewError = error as? ContinueAsNewError {
            self.logger.debug("Workflow requested continue as new")
            self.stateMachine.continueAsNew(continueAsNewError)
        } else if Task.isCancelled && error.isTemporalCancellation {
            self.logger.debug("Workflow raised a cancellation.")
            self.stateMachine.cancelWorkflowExecution()
        } else if let temporalFailureError = error as? any TemporalFailureError {
            // If the thrown error is a temporal failure error it needs to fail the whole
            // workflow.
            let failure = self.failureConverter.convertError(temporalFailureError, payloadConverter: self.payloadConverter)
            self.stateMachine.workflowFinished(failure: failure)
        } else {
            // If it's any other error type we need to fail the activation
            // so that the workflow task can be retried
            let failure = self.failureConverter.convertError(error, payloadConverter: self.payloadConverter)
            self.stateMachine.workflowTaskFailed(failure: failure)
        }
    }
}

extension WorkflowInstance {
    struct Implementation: InterceptorImplementation {
        let interceptors: [any WorkflowInboundInterceptor]
        let executor: WorkflowTaskExecutor
    }
}

extension WorkflowInstance.Implementation {
    func executeWorkflow<Workflow: WorkflowDefinition>(
        workflow: Workflow,
        context: InternalWorkflowContext,
        publicContext: WorkflowContext<Workflow>,
        input: ExecuteWorkflowInput<Workflow>
    ) async throws -> Workflow.Output {
        try await Temporal.InternalWorkflowContext.$currentExecutor.withValue(self.executor) {
            try await Temporal.InternalWorkflowContext.$current.withValue(context) {
                try await intercept((any WorkflowInboundInterceptor).executeWorkflow, input: input) { input in
                    var workflow = workflow
                    return try await workflow.run(context: publicContext, input: input.input)
                }
            }
        }
    }

    func handleSignal<Signal: WorkflowSignalDefinition>(
        workflow: Signal.Workflow,
        context: InternalWorkflowContext,
        publicContext: WorkflowContext<Signal.Workflow>,
        input: HandleSignalInput<Signal>
    ) async throws {
        try await Temporal.InternalWorkflowContext.$currentExecutor.withValue(self.executor) {
            try await Temporal.InternalWorkflowContext.$current.withValue(context) {
                try await intercept((any WorkflowInboundInterceptor).handleSignal, input: input) { input in
                    try await input.definition.run(
                        workflow: workflow,
                        context: publicContext,
                        input: input.input
                    )
                }
            }
        }
    }

    func handleQuery<Query: WorkflowQueryDefinition>(
        workflow: Query.Workflow,
        context: InternalWorkflowContext,
        input: HandleQueryInput<Query>
    ) throws -> Query.Output {
        try Temporal.InternalWorkflowContext.$currentExecutor.withValue(self.executor) {
            try Temporal.InternalWorkflowContext.$current.withValue(context) {
                try intercept((any WorkflowInboundInterceptor).handleQuery, input: input) { input in
                    try input.definition.run(
                        workflow: workflow,
                        input: input.input
                    )
                }
            }
        }
    }

    func handleUpdate<Update: WorkflowUpdateDefinition>(
        workflow: Update.Workflow,
        context: InternalWorkflowContext,
        publicContext: WorkflowContext<Update.Workflow>,
        input: HandleUpdateInput<Update>
    ) async throws -> Update.Output {
        try await Temporal.InternalWorkflowContext.$currentExecutor.withValue(self.executor) {
            try await Temporal.InternalWorkflowContext.$current.withValue(context) {
                try await Temporal.InternalWorkflowContext.$currentUpdateInfo.withValue(
                    WorkflowUpdateInfo(id: input.id, name: input.name)
                ) {
                    try await intercept((any WorkflowInboundInterceptor).handleUpdate, input: input) { input in
                        try await input.definition.run(
                            workflow: workflow,
                            context: publicContext,
                            input: input.input
                        )
                    }
                }
            }
        }
    }

    func validateUpdate<Update: WorkflowUpdateDefinition>(
        workflow: Update.Workflow,
        context: InternalWorkflowContext,
        input: HandleUpdateInput<Update>
    ) throws {
        try Temporal.InternalWorkflowContext.$currentExecutor.withValue(self.executor) {
            try Temporal.InternalWorkflowContext.$current.withValue(context) {
                try Temporal.InternalWorkflowContext.$currentUpdateInfo.withValue(
                    WorkflowUpdateInfo(id: input.id, name: input.name)
                ) {
                    try intercept((any WorkflowInboundInterceptor).validateUpdate, input: input) { input in
                        try input.definition.validateInput(workflow: workflow, input.input)
                    }
                }
            }
        }
    }
}
