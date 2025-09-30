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

import struct Foundation.Date

/// The execution context available during workflow execution.
package struct WorkflowContext: Sendable {
    /// Internal state machine for workflow execution.
    private let stateMachine: WorkflowStateMachineStorage

    /// Outbound interceptors for workflow operations.
    private let outboundInterceptors: [any WorkflowOutboundInterceptor]

    /// Implementation delegate for interceptor processing.
    let implementation: Implementation

    /// The logger passed to the workflow execution.
    let logger: Logger

    /// Information about the current workflow execution.
    ///
    /// Provides access to workflow metadata including identifiers, timing information,
    /// configuration, and parent workflow details.
    let info: WorkflowInfo

    /// The data converter used for payload serialization and deserialization.
    ///
    /// This converter handles the transformation between Swift types and Temporal's
    /// internal payload format.
    let payloadConverter: any PayloadConverter

    /// A deterministic random number generator for workflow use.
    var randomNumberGenerator: RandomNumberGenerator {
        WorkflowRandomNumberGenerator(stateMachine: self.stateMachine)
    }

    /// Indicates whether all update and signal handlers have finished executing.
    var allHandlersFinished: Bool {
        self.stateMachine.allHandlersFinished()
    }

    /// Indicates whether the workflow is currently in replay mode.
    package var isReplaying: Bool {
        self.stateMachine.isReplaying()
    }

    var now: Date {
        self.stateMachine.now()
    }

    /// The current search attributes for the workflow.
    var searchAttributes: SearchAttributeCollection {
        self.stateMachine.searchAttributes()
    }

    func upsertSearchAttributes(_ searchAttributes: SearchAttributeCollection) {
        self.stateMachine.upsertSearchAttributes(searchAttributes)
    }

    /// User specified details for this workflow that may appear in UI/CLI.
    var currentDetails: String? {
        get {
            self.stateMachine.currentDetails()
        }
        set {
            self.stateMachine.setCurrentDetails(newValue)
        }
    }

    func ensureWorkflowStateModificationIsSafe() {
        self.stateMachine.ensureWorkflowStateModificationIsSafe()
    }

    /// Internal method to update current details when context is immutable.
    func updateCurrentDetails(_ newValue: String?) {
        self.stateMachine.setCurrentDetails(newValue)
    }

    /// A boolean value that indicates whether continue as new was suggested.
    var continueAsNewSuggested: Bool {
        self.stateMachine.continueAsNewSuggested()
    }

    /// Current number of events in the history.
    var currentHistoryLength: Int {
        self.stateMachine.currentHistoryLength()
    }

    /// Current size of the history in bytes.
    var currentHistorySize: Int {
        self.stateMachine.currentHistorySize()
    }

    package init(
        stateMachine: WorkflowStateMachineStorage,
        workflowInfo: WorkflowInfo,
        payloadConverter: any PayloadConverter,
        outboundInterceptors: [any WorkflowOutboundInterceptor],
        logger: Logger
    ) {
        self.stateMachine = stateMachine
        self.info = workflowInfo
        self.payloadConverter = payloadConverter
        self.outboundInterceptors = outboundInterceptors
        self.implementation = .init(
            interceptors: outboundInterceptors,
            stateMachine: stateMachine,
            payloadConverter: payloadConverter
        )
        self.logger = logger
    }

    func sleep(for duration: Duration, summary: String? = nil) async throws {
        try await self.implementation.sleep(
            input: .init(
                duration: duration,
                summary: summary
            )
        )
    }

    private enum TimeoutResult<Return: Sendable, Failure: Error> {
        case sleepReturned
        case sleepThrew
        case bodyReturned(Return)
        case bodyThrew(Failure)
    }

    func timeout<Return: Sendable, Failure: Error>(
        for duration: Duration,
        body: @Sendable @escaping () async throws(Failure) -> Return
    ) async throws(Failure) -> Return {
        try await withTaskGroup(of: TimeoutResult<Return, Failure>.self) { group in
            group.addTask {
                do {
                    try await self.sleep(for: duration)
                    return .sleepReturned
                } catch {
                    return .sleepThrew
                }
            }
            group.addTask {
                do {
                    return .bodyReturned(try await body())
                } catch {
                    // TODO: Investigate why this requires a force cast with the compiler folks
                    return .bodyThrew(error as! Failure)
                }
            }

            // This force unwrap is safe since we have two guaranteed child tasks
            // If the method below
            let result = await group.next()!
            switch result {
            case .sleepReturned, .sleepThrew:
                // We either timed out or our parent task got cancelled
                // so now we have to cancel the body child task and wait for its result
                group.cancelAll()
                let nextResult = await group.next()!
                switch nextResult {
                case .sleepReturned, .sleepThrew:
                    fatalError("The sleep child task already returned")
                case .bodyReturned(let value):
                    return Result<Return, Failure>.success(value)
                case .bodyThrew(let error):
                    return Result<Return, Failure>.failure(error)
                }
            case .bodyReturned(let value):
                // We can cancel the sleep now and ignore any error from it
                group.cancelAll()
                _ = await group.next()
                return Result<Return, Failure>.success(value)
            case .bodyThrew(let error):
                // We can cancel the sleep now and ignore any error from it
                group.cancelAll()
                _ = await group.next()
                return Result<Return, Failure>.failure(error)
            }
        }.get()
    }

    func withCancellationShield<Result: Sendable>(_ operation: sending @escaping () async throws -> Result) async throws -> Result {
        try await self.stateMachine.withCancellationShield(operation)
    }

    func condition(_ condition: @escaping () -> Bool) async throws {
        try await self.stateMachine.condition(condition)
    }

    func patch(_ id: String) -> Bool {
        self.stateMachine.patch(id)
    }

    func deprecatePatch(_ id: String) {
        self.stateMachine.deprecatePatch(id)
    }

    func executeActivity<each Input: Sendable, Output: Sendable>(
        name: String,
        options: ActivityOptions,
        input: repeat each Input,
        outputType: Output.Type = Output.self
    ) async throws -> Output {
        try await self.implementation.executeActivity(
            input: ScheduleActivityInput<repeat each Input>(
                name: name,
                options: options,
                headers: [:],
                input: (repeat each input)
            )
        )
    }

    // MARK: Local Activity Execution

    func executeLocalActivity<each Input: Sendable, Output: Sendable>(
        name: String,
        options: LocalActivityOptions,
        input: repeat each Input,
        outputType: Output.Type = Output.self
    ) async throws -> Output {
        try await self.implementation.executeLocalActivity(
            input: ScheduleLocalActivityInput<repeat each Input>(
                name: name,
                options: options,
                headers: [:],
                input: (repeat each input)
            )
        )
    }

    // MARK: Child workflow

    func startChildWorkflow<Workflow: WorkflowDefinition>(
        workflowType: Workflow.Type = Workflow.self,
        options: ChildWorkflowOptions = .init(),
        input: Workflow.Input
    ) async throws -> ChildWorkflowHandle<Workflow> {
        let untypedChildWorkflowHandle = try await self.startChildWorkflow(
            name: Workflow.name,
            options: options,
            inputs: input
        )
        return ChildWorkflowHandle(untypedWorkflowHandle: untypedChildWorkflowHandle)
    }

    func startChildWorkflow<each Input: Sendable>(
        name: String,
        options: ChildWorkflowOptions = .init(),
        inputs: repeat each Input
    ) async throws -> UntypedChildWorkflowHandle {
        return try await self.implementation.startChildWorkflow(
            input: StartChildWorkflowInput<repeat each Input>(
                name: name,
                options: options,
                headers: [:],
                input: (repeat each inputs)
            )
        )
    }

    // MARK: Memo

    func getMemoValue<T>(for key: String) async throws -> T? {
        let memo = self.stateMachine.memo()
        guard let rawValue = memo[key] else {
            return nil
        }

        do {
            return try self.payloadConverter.convertPayloadHandlingVoid(rawValue.payload, as: T.self)
        } catch {
            throw ArgumentError(message: "Failed to convert memo value to type \(T.self)")
        }
    }

    func upsertMemo(_ memo: [String: Any?]) async throws {
        guard memo.count > 0 else {
            throw ArgumentError(message: "At least one memo update required")
        }

        var convertedMemo = [String: TemporalRawValue?]()
        for (key, value) in memo {
            guard let value else {
                convertedMemo[key] = .some(nil)
                continue
            }

            do {
                let payload = try self.payloadConverter.convertValueHandlingVoid(value)
                convertedMemo[key] = .init(payload)
            } catch {
                throw ArgumentError(message: "Failed to convert memo value for key \(key). Underlying error \(type(of: error))")
            }
        }
        self.stateMachine.upsertMemo(convertedMemo)
    }

    func memo() -> [String: TemporalRawValue] {
        self.stateMachine.memo()
    }

    // MARK: ContinueAsNew

    func makeContinueAsNewError<each Input: Sendable>(
        options: ContinueAsNewOptions,
        input: repeat each Input
    ) async throws -> ContinueAsNewError {
        try await self.implementation.makeContinueAsNewError(
            context: self,
            input: MakeContinueAsNewErrorInput<repeat each Input>(
                options: options,
                headers: [:],
                input: (repeat each input)
            )
        )
    }
}

extension WorkflowContext {
    struct Implementation: InterceptorImplementation {
        let interceptors: [any WorkflowOutboundInterceptor]
        let stateMachine: WorkflowStateMachineStorage
        let payloadConverter: any PayloadConverter
    }
}

extension WorkflowContext.Implementation {
    func sleep(
        input: HandleSleepInput
    ) async throws {
        try await intercept(Interceptor.handleSleep, input: input) { input in
            try await self.stateMachine.sleep(for: input.duration, summary: input.summary)
        }
    }

    func executeActivity<each Input: Sendable, Output: Sendable>(
        input: ScheduleActivityInput<repeat each Input>
    ) async throws -> Output {
        try await intercept(Interceptor.executeActivity, input: input) { input in
            // If payload conversion fails this will potentially bubble up and fail the run/handler method
            // That's expected and should normally cause a workflow task failure.
            let inputPayloads = try self.payloadConverter.convertValues(repeat each input.input)
            let outputPayload = try await self.stateMachine.executeActivity(
                // TODO: Support dynamic activity
                activityType: input.name,
                options: .remote(input.options),
                workflowTaskQueue: Workflow.info.taskQueue,
                headers: input.headers,
                input: inputPayloads
            )
            // If payload conversion fails this will potentially bubble up and fail the run/handler method
            // That's expected and should normally cause a workflow task failure.
            return try self.payloadConverter.convertPayloadHandlingVoid(
                outputPayload
            )
        }
    }

    func executeLocalActivity<each Input: Sendable, Output: Sendable>(
        input: ScheduleLocalActivityInput<repeat each Input>
    ) async throws -> Output {
        try await intercept(Interceptor.executeLocalActivity, input: input) { input in
            // If payload conversion fails this will potentially bubble up and fail the run/handler method
            // That's expected and should normally cause a workflow task failure.
            let inputPayloads = try self.payloadConverter.convertValues(repeat each input.input)
            let outputPayload = try await self.stateMachine.executeActivity(
                // TODO: Support dynamic activity
                activityType: input.name,
                options: .local(input.options),
                workflowTaskQueue: Workflow.info.taskQueue,
                headers: input.headers,
                input: inputPayloads
            )
            // If payload conversion fails this will potentially bubble up and fail the run/handler method
            // That's expected and should normally cause a workflow task failure.
            return try self.payloadConverter.convertPayloadHandlingVoid(
                outputPayload
            )
        }
    }

    func startChildWorkflow<each Input: Sendable>(
        input: StartChildWorkflowInput<repeat each Input>
    ) async throws -> UntypedChildWorkflowHandle {
        try await intercept(Interceptor.startChildWorkflow, input: input) { input in
            let inputPayloads: [TemporalPayload]
            do {
                inputPayloads = try self.payloadConverter.convertValues(repeat each input.input)
            } catch {
                throw ArgumentError(message: "Failed to convert inputs for child workflow '\(input.name)'. Underlying error \(error)")
            }

            return try await self.stateMachine.startChildWorkflow(
                namespace: Workflow.info.namespace,
                taskQueue: Workflow.info.taskQueue,
                workflowName: input.name,
                headers: input.headers,
                inputs: inputPayloads,
                childWorkflowOptions: input.options,
                interceptors: self.interceptors
            )
        }
    }

    func makeContinueAsNewError<each Input: Sendable>(
        context: WorkflowContext,
        input: MakeContinueAsNewErrorInput<repeat each Input>
    ) async throws -> ContinueAsNewError {
        try await intercept(Interceptor.makeContinueAsNewError, input: input) { input in
            let inputPayloads: [TemporalPayload]
            do {
                inputPayloads = try self.payloadConverter.convertValues(repeat each input.input)
            } catch {
                throw ArgumentError(message: "Unable to convert workflow inputs for continue as new error. Underlying error: \\(error)")
            }

            return try ContinueAsNewError(
                workflowContext: context,
                headers: input.headers,
                inputs: inputPayloads,
                options: input.options,
                payloadConverter: self.payloadConverter
            )
        }
    }
}
