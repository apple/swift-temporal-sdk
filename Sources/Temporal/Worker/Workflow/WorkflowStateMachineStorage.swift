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

import struct Foundation.Date

// This type is unchecked Sendable since it enforces the safe access
// by checking that every call from a workflow context is coming from
// the right executor.
// All calls from the workflow runner must happen off the executor.
// This is fine though since we manually run the jobs of the executor so no
// concurrent access can happen.
package final class WorkflowStateMachineStorage: @unchecked Sendable {
    private enum Access {
        case reading
        case mutating
    }

    private var stateMachine: WorkflowStateMachine {
        _read {
            // Read-only access is allowed in frozen state, therefore, impose a more lenient check here.
            self.ensureOnExecutor(access: .reading)
            yield self._stateMachine
        }
        _modify {
            // mutating methods might add commands which is not allowed when context is frozen.
            self.ensureOnExecutor(access: .mutating)
            yield &self._stateMachine
        }
    }
    private var _stateMachine = WorkflowStateMachine()
    private let payloadConverter: any PayloadConverter
    private let failureConverter: any FailureConverter
    private let executor: WorkflowTaskExecutor

    package init(
        executor: WorkflowTaskExecutor,
        payloadConverter: any PayloadConverter,
        failureConverter: any FailureConverter
    ) {
        self.executor = executor
        self.payloadConverter = payloadConverter
        self.failureConverter = failureConverter
    }

    func ensureWorkflowStateModificationIsSafe() {
        self.ensureOnExecutor(access: .reading)
    }

    func updateRandomnessSeed(_ seed: UInt64) {
        self.stateMachine.updateRandomnessSeed(seed)
    }

    func generateNextRandomNumber() -> UInt64 {
        return self.stateMachine.generateNextRandomNumber()
    }

    func sleep(for duration: Duration, summary: String?) async throws {
        // If we are already cancelled no point in scheduling a timer
        if Task.isCancelled {
            throw CanceledError(
                message: "Task cancelled before sleep started"
            )
        }

        if duration < .zero {
            throw ArgumentError(message: "Sleep duration cannot be less than 0")
        }

        // If duration is zero, we make it one millisecond. It was decided a 0 duration still makes
        // a timer to ensure determinism if a timer's duration is altered from non-zero to zero or vice versa.
        // This is something that other SDKs do as well so that zero timers are creating events in temporal.
        var duration = duration
        if duration == .zero {
            duration = .milliseconds(1)
        }

        let convertedSummary = try summary.flatMap { try self.payloadConverter.convertValue($0) }

        let sequenceNumber = self.stateMachine.nextSequenceNumber()
        try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                self.stateMachine.sleep(
                    for: duration,
                    summary: convertedSummary,
                    sequenceNumber: sequenceNumber,
                    continuation: continuation
                )
            }
        } onCancel: {
            // We don't have to handle the case that this gets called before the operation
            // since we are checking at the beginning of the method if we are already cancelled
            // and the workflow's task can only get cancelled by the workflow instance.
            self.stateMachine.cancelTimer(sequenceNumber: sequenceNumber)?.resume(
                throwing: CanceledError(
                    message: "Sleep cancelled"
                )
            )
        }
    }

    func patch(_ id: String) -> Bool {
        self.stateMachine.patch(id, false)
    }

    func deprecatePatch(_ id: String) {
        self.stateMachine.patch(id, true)
    }

    func notifyHasPatch(_ notifyHasPatch: Coresdk_WorkflowActivation_NotifyHasPatch) {
        self.stateMachine.notifyHasPatch(notifyHasPatch.patchID)
    }

    func fireTimer(_ fireTimer: Coresdk_WorkflowActivation_FireTimer) {
        self.stateMachine.fireTimer(fireTimer)?.resume()
    }

    func handlerStarted() {
        self.stateMachine.handlerStarted()
    }

    func handlerFinished() {
        self.stateMachine.handlerFinished()
    }

    func allHandlersFinished() -> Bool {
        // This is expected to be called from the workflow instance
        // since that is running all the wait conditions.
        return self.stateMachine.allHandlersFinished()
    }

    func withCancellationShield<Result: Sendable>(_ operation: sending @escaping () async throws -> Result) async throws -> Result {
        try await Task(executorPreference: self.executor, operation: operation).value
    }

    func condition(_ condition: @escaping () -> Bool) async throws {
        let id = self.stateMachine.condition(condition)
        try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                let continuation = self.stateMachine.storeConditionContinuation(id: id, continuation: continuation)

                // We use the same error message, we cannot predict which resume comes first due to an expected race condition,
                // where the onCancel removes the condition but this resume is scheduled first.
                continuation?.resume(throwing: CanceledError(message: "Wait condition cancelled"))
            }
        } onCancel: {
            // We should ensure this during runtime by giving the instance a separate executor which we can assert on.
            let continuation = self.stateMachine.cancelConditionContinuation(id: id)
            continuation?.resume(throwing: CanceledError(message: "Wait condition cancelled"))
        }
    }

    func forceCancelOutstandingContinuations() {
        stateMachine.forceCancelOutstandingContinuations()
    }

    func uncancellableCondition(_ condition: @escaping () -> Bool) async {
        let id = self.stateMachine.condition(condition)
        // This force unwrap is safe since the continuation for this condition cannot be cancelled.
        try! await withCheckedThrowingContinuation { continuation in
            let continuation = self.stateMachine.storeConditionContinuation(id: id, continuation: continuation)
            precondition(continuation == nil, "The continuation is uncancellable so it must not be returned here")
        }
    }

    func executeActivity(
        activityType: String,
        options: ActivityExecutionOptions,
        workflowTaskQueue: String,
        headers: [String: TemporalPayload],
        input: [TemporalPayload]
    ) async throws -> TemporalPayload {
        if Task.isCancelled {
            throw CanceledError(message: "Activity cancelled before scheduled")
        }

        var options = options
        let isLocal = options.isLocal
        while true {
            let id = self.stateMachine.nextSequenceNumber()
            let result = try await withTaskCancellationHandler {
                try await withCheckedThrowingContinuation { continuation in
                    self.stateMachine.scheduleActivityExecution(
                        id: id,
                        activityType: activityType,
                        options: options,
                        workflowTaskQueue: workflowTaskQueue,
                        headers: headers,
                        input: input,
                        continuation: continuation
                    )
                }
            } onCancel: {
                // No need to worry about this being called before the actual operation as we check earlier in the method and there are no possible
                // suspension points.
                self.stateMachine.cancelActivity(id: id, isLocal: isLocal)
            }

            switch result.status {
            case .completed(let completed):
                return .init(temporalAPIPayload: completed.result)
            case .failed(let failed):
                let error = self.failureConverter.convertTemporalFailure(
                    .init(temporalAPIFailure: failed.failure),
                    payloadConverter: self.payloadConverter
                )
                throw error
            case .cancelled(let cancelled):
                let error = self.failureConverter.convertTemporalFailure(
                    .init(temporalAPIFailure: cancelled.failure),
                    payloadConverter: self.payloadConverter
                )
                throw error
            case .backoff(let backoff):
                try await self.sleep(for: .init(backoff.backoffDuration), summary: "LocalActivityBackoff")
                options = options.withBackoff(backoff)
            case .none:
                throw UnknownError(message: "Unknown activity resolution status")
            }
        }
    }

    func resolveActivity(_ resolveActivity: Coresdk_WorkflowActivation_ResolveActivity) {
        guard let continuation = self.stateMachine.resolveActivity(resolveActivity) else {
            // If there is no continuation the activity was cancelled and the cancellation was already reported to the workflow.
            return
        }

        continuation.resume(returning: resolveActivity.result)
    }

    func conditions() -> [UInt32: () -> Bool] {
        return self.stateMachine.conditions()
    }

    func resumeCondition(id: UInt32) {
        self.stateMachine.removeCondition(id: id).resume()
    }

    func queryFinished(id: String, temporalPayload: TemporalPayload) {
        self.stateMachine.queryFinished(id: id, temporalPayload: temporalPayload)
    }

    func queryFailed(id: String, temporalFailure: TemporalFailure) {
        self.stateMachine.queryFailed(id: id, temporalFailure: temporalFailure)
    }

    func updateAccepted(id: String) {
        self.stateMachine.updateAccepted(id: id)
    }

    func updateCompleted(id: String, temporalPayload: TemporalPayload) {
        self.stateMachine.updateCompleted(id: id, temporalPayload: temporalPayload)
    }

    func updateRejected(id: String, temporalFailure: TemporalFailure) {
        self.stateMachine.updateRejected(id: id, temporalFailure: temporalFailure)
    }

    func startChildWorkflow(
        namespace: String,
        taskQueue: String,
        workflowName: String,
        headers: [String: TemporalPayload],
        inputs: [TemporalPayload],
        childWorkflowOptions: ChildWorkflowOptions,
        interceptors: [any WorkflowOutboundInterceptor]
    ) async throws -> UntypedChildWorkflowHandle {
        // If we are already cancelled no point in scheduling a timer
        if Task.isCancelled {
            throw CanceledError(
                message: "Task cancelled before child workflow scheduled"
            )
        }

        let sequenceNumber = self.stateMachine.nextSequenceNumber()
        let state = UntypedChildWorkflowHandle.State(resolutionState: .unresolved(sequenceNumber: sequenceNumber))
        let (workflowID, firstExecutionRunID) = try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                self.stateMachine.startChildWorkflow(
                    sequenceNumber: sequenceNumber,
                    namespace: namespace,
                    taskQueue: taskQueue,
                    workflowName: workflowName,
                    headers: headers,
                    inputs: inputs,
                    childWorkflowOptions: childWorkflowOptions,
                    state: state,
                    continuation: continuation
                )
            }
        } onCancel: {
            // We don't have to handle the case that this gets called before the operation
            // since we are checking at the beginning of the method if we are already cancelled
            // and the workflow's task can only get cancelled by the workflow or workflow instance.
            // TODO: Ensure the above
            self.stateMachine.cancelChildWorkflow(sequenceNumber: sequenceNumber)
        }

        return UntypedChildWorkflowHandle(
            id: workflowID,
            firstExecutionRunID: firstExecutionRunID,
            state: state,
            stateMachine: self,
            executor: self.executor,
            interceptors: interceptors,
            payloadConverter: self.payloadConverter,
            failureConverter: self.failureConverter
        )
    }

    func resolveStartChildWorkflow(
        _ resolveChildWorkflowExecutionStart: Coresdk_WorkflowActivation_ResolveChildWorkflowExecutionStart
    ) async {
        let (workflowID, continuation) = self.stateMachine.removeStartChildWorkflowContinuation(
            sequenceNumber: resolveChildWorkflowExecutionStart.seq
        )

        switch resolveChildWorkflowExecutionStart.status {
        case .succeeded(let succeeded):
            continuation.resume(returning: (workflowID, succeeded.runID))
        case .failed(let failed):
            switch failed.cause {
            case .workflowAlreadyExists:
                continuation.resume(throwing: WorkflowAlreadyStartedError(workflowID: workflowID, runID: "", workflowName: failed.workflowType))
            case .unspecified, .UNRECOGNIZED:
                continuation.resume(
                    throwing: UnknownError(message: "Unknown child start fail cause \(failed.cause)")
                )
            }
        case .cancelled(let cancelled):
            continuation.resume(
                throwing: self.failureConverter.convertTemporalFailure(
                    .init(temporalAPIFailure: cancelled.failure),
                    payloadConverter: self.payloadConverter
                )
            )
        case .none:
            continuation.resume(
                throwing: UnknownError(message: "Unknown start child workflow resolution status")
            )
        }
    }

    func resolveChildWorkflowResult(
        sequenceNumber: UInt32,
        result: Coresdk_ChildWorkflow_ChildWorkflowResult
    ) {
        let state = self.stateMachine.resolveChildWorkflowResult(
            sequenceNumber: sequenceNumber
        )
        state.resolutionState = .resolved(result: result)
    }

    func cancelChildWorkflow(sequenceNumber: UInt32) {
        self.stateMachine.cancelChildWorkflow(sequenceNumber: sequenceNumber)
    }

    func signalChildWorkflow(
        childWorkflowID: String,
        signalName: String,
        headers: [String: TemporalPayload],
        inputs: [TemporalPayload]
    ) async throws {
        // If we are already cancelled no point in scheduling a timer
        if Task.isCancelled {
            throw CanceledError(
                message: "Task cancelled before signal scheduled"
            )
        }

        let sequenceNumber = self.stateMachine.nextSequenceNumber()
        try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                self.stateMachine.signalChildWorkflow(
                    sequenceNumber: sequenceNumber,
                    childWorkflowID: childWorkflowID,
                    signalName: signalName,
                    headers: headers,
                    inputs: inputs,
                    continuation: continuation
                )
            }
        } onCancel: {
            // We don't have to handle the case that this gets called before the operation
            // since we are checking at the beginning of the method if we are already cancelled
            // and the workflow's task can only get cancelled by the workflow instance.
            self.stateMachine.cancelExternalSignalWorkflow(sequenceNumber: sequenceNumber)
        }
    }

    func resolveExternalWorkflowSignal(
        _ resolveSignalExternalWorkflow: Coresdk_WorkflowActivation_ResolveSignalExternalWorkflow
    ) async {
        let continuation = self.stateMachine.removeExternalWorkflowContinuation(sequenceNumber: resolveSignalExternalWorkflow.seq)

        if resolveSignalExternalWorkflow.hasFailure {
            let temporalFailure = self.failureConverter.convertTemporalFailure(
                .init(temporalAPIFailure: resolveSignalExternalWorkflow.failure),
                payloadConverter: self.payloadConverter
            )
            continuation.resume(throwing: temporalFailure)
        } else {
            continuation.resume()
        }
    }

    func workflowFinished(temporalPayload: TemporalPayload) {
        self.stateMachine.workflowFinished(temporalPayload: temporalPayload)
    }

    func workflowFinished(temporalFailure: TemporalFailure) {
        self.stateMachine.workflowFinished(temporalFailure: temporalFailure)
    }

    func workflowTaskFailed(temporalFailure: TemporalFailure) {
        self.stateMachine.workflowTaskFailed(temporalFailure: temporalFailure)
    }

    func activate(with activation: Coresdk_WorkflowActivation_WorkflowActivation) {
        self.stateMachine.activate(with: activation)
    }

    func isReplaying() -> Bool {
        return self.stateMachine.isReplaying()
    }

    func now() -> Date {
        return self.stateMachine.now()
    }

    func continueAsNewSuggested() -> Bool {
        return self.stateMachine.continueAsNewSuggested()
    }

    func currentHistorySize() -> Int {
        return self.stateMachine.currentHistorySize()
    }

    func currentHistoryLength() -> Int {
        return self.stateMachine.currentHistoryLength()
    }

    // MARK: Memo

    func memo() -> [String: TemporalRawValue] {
        return self.stateMachine.memo()
    }

    func upsertMemo(_ memo: [String: TemporalRawValue?]) {
        self.stateMachine.upsertMemo(memo)
    }

    func setMemo(_ memo: [String: TemporalRawValue]) {
        self.stateMachine.setMemo(memo)
    }

    // MARK: Search Attributes

    func setSearchAttributes(_ searchAttributes: SearchAttributeCollection) {
        self.stateMachine.setSearchAttributes(searchAttributes)
    }

    func searchAttributes() -> SearchAttributeCollection {
        return stateMachine.searchAttributes()
    }

    func upsertSearchAttributes(_ searchAttributes: SearchAttributeCollection) {
        self.stateMachine.upsertSearchAttributes(searchAttributes)
    }

    // MARK: Current Details

    func currentDetails() -> String? {
        return stateMachine.currentDetails()
    }

    func setCurrentDetails(_ currentDetails: String?) {
        self.stateMachine.setCurrentDetails(currentDetails)
    }

    func continueAsNew(_ continueAsNewError: ContinueAsNewError) {
        self.stateMachine.continueAsNew(continueAsNewError)
    }

    func commands() -> WorkflowStateMachine.CommandsAction {
        return self.stateMachine.commands()
    }

    private func ensureOnExecutor(access: Access) {
        // Allow access if the workflow instance itself is modifying the state
        if WorkflowInstance.isOnWorkflowInstance {
            return
        }

        // Prevent any mutating state machine operations when context is frozen
        if access == .mutating && WorkflowInstance.isWorkflowStateFrozen {
            fatalError(
                "WorkflowStateMachine operations are not allowed when context is frozen. This typically occurs during workflow initialization, query execution, or update validation."
            )
        }

        // This is using custom logic instead of preconditionIsolated to ensure
        // the error messages are printed on crash.
        withUnsafeCurrentTask { currentTask in
            guard let currentTask else {
                fatalError("Current task not found")
            }
            guard currentTask.unownedTaskExecutor == executor.asUnownedTaskExecutor() else {
                fatalError("Current task executor mismatch")
            }
        }
    }
}
