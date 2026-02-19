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

import SwiftProtobuf

import struct Foundation.Date
import struct Foundation.UUID

struct WorkflowStateMachine: ~Copyable {
    /// The state of the workflow.
    enum State: ~Copyable {
        /// The state when the workflow is actively running.
        struct Active: ~Copyable {
            /// Temporal requires each command to have a unique sequence number within its operation type.
            ///
            /// Each operation type (timers, activities, conditions, child workflows, external signals) maintains
            /// its own independent sequence counter. These numbers are used to identify which activation job
            /// belongs to which command.
            ///
            /// For example, if a workflow schedules a timer which we assign sequence number 1 to,
            /// later we will get an activation job of type fireTimer with sequence number 1. This allows us
            /// to resume the correct continuation belonging to that timer.

            /// Next sequence number for timer operations (sleep).
            var nextTimerSequenceNumber: UInt32

            /// Next sequence number for activity executions (both local and remote).
            var nextActivitySequenceNumber: UInt32

            /// Next sequence number for wait conditions.
            var nextConditionSequenceNumber: UInt32

            /// Next sequence number for child workflow executions.
            var nextChildWorkflowSequenceNumber: UInt32

            /// Next sequence number for signaling external workflows (including child workflows).
            var nextExternalSignalSequenceNumber: UInt32

            /// Number of current running and unfinished handlers.
            var numberOfActiveHandlers: Int

            /// Whether or not the activation is replaying past events.
            var isReplaying: Bool

            /// The current timestamp for the workflow.
            var now: Date

            /// Whether continue as new was suggested.
            var continueAsNewSuggested: Bool

            /// Current number of events in the history.
            var currentHistoryLength: Int

            /// Current size of the history in bytes.
            var currentHistorySize: Int

            /// The generated commands that need to be sent to the temporal service after processing the activation.
            var commands: [Coresdk.WorkflowCommands.WorkflowCommand]

            /// These are the current timer continuations that the workflow is waiting on.
            ///
            /// Different temporal commands such as scheduling a timer will create a continuation.
            /// These continuations are keyed by their corresponding sequence number.
            var timerContinuations: [UInt32: CheckedContinuation<Void, any Error>]

            /// These are the current activity continuations that the workflow is waiting on.
            var activityContinuations: [UInt32: CheckedContinuation<Coresdk.ActivityResult.ActivityResolution, any Error>]

            /// These are the continuations for all the current wait conditions.
            var waitConditionContinuations: [UInt32: (() -> Bool, CheckedContinuation<Void, any Error>?)]

            /// These are the current child workflow start continuations that the workflow is waiting on.
            var childWorkflowStartContinuations: [UInt32: (String, CheckedContinuation<(String, String), any Error>)]

            /// These are the current child workflow states tracked by child workflow handles.
            var childWorkflowResultStates: [UInt32: UntypedChildWorkflowHandle.State]

            /// These are the current external workflow signal continuations that the workflow is waiting on.
            var externalWorkflowSignalContinuations: [UInt32: (CheckedContinuation<Void, any Error>)]

            /// Patches that have been detected.
            var patchesNotified: Set<String>

            /// Cached results for patches already processed.
            var patchesMemoized: [String: Bool]

            /// An activation error leads to workflow task failure which leads to temporal retrying the workflow.
            ///
            /// This is different than workflow failure which signals an end state. Concretely, throwing a
            /// ``TemporalFailureError`` from the workflows run method is considered a workflow failure
            /// whereas throwing any other error is considered a workflow task failure.
            ///
            /// We cannot transition to another state yet because handlers might still have suspended continuations which
            /// we can only resume once we get a `RemoveFromCache` job.
            var activationFailure: TemporalFailure?

            /// The headers passed into the initial execution.
            var headers: [String: TemporalPayload]

            /// The current memo.
            var memo: [String: TemporalRawValue]

            /// The current search attribute key-value pairs.
            var searchAttributes: SearchAttributeCollection

            /// The current details of the workflow execution.
            var currentDetails: String?

            /// The random number generator.
            var randomNumberGenerator: PCGRandomNumberGenerator
        }
        case active(Active)
    }

    private var state: State = .active(
        .init(
            nextTimerSequenceNumber: 0,
            nextActivitySequenceNumber: 0,
            nextConditionSequenceNumber: 0,
            nextChildWorkflowSequenceNumber: 0,
            nextExternalSignalSequenceNumber: 0,
            numberOfActiveHandlers: 0,
            isReplaying: false,
            now: .now,
            continueAsNewSuggested: false,
            currentHistoryLength: 0,
            currentHistorySize: 0,
            commands: [],
            timerContinuations: [:],
            activityContinuations: [:],
            waitConditionContinuations: [:],
            childWorkflowStartContinuations: [:],
            childWorkflowResultStates: [:],
            externalWorkflowSignalContinuations: [:],
            patchesNotified: [],
            patchesMemoized: [:],
            headers: [:],
            memo: [:],
            searchAttributes: .init(),
            currentDetails: nil,
            randomNumberGenerator: .init(seed: 1)
        )
    )

    init() {}

    init(state: consuming State) {
        self.state = state
    }

    mutating func nextTimerSequenceNumber() -> UInt32 {
        switch consume self.state {
        case .active(var active):
            let sequenceNumber = active.nextTimerSequenceNumber
            active.nextTimerSequenceNumber += 1
            self = .init(state: .active(active))
            return sequenceNumber
        }
    }

    mutating func nextActivitySequenceNumber() -> UInt32 {
        switch consume self.state {
        case .active(var active):
            let sequenceNumber = active.nextActivitySequenceNumber
            active.nextActivitySequenceNumber += 1
            self = .init(state: .active(active))
            return sequenceNumber
        }
    }

    mutating func nextConditionSequenceNumber() -> UInt32 {
        switch consume self.state {
        case .active(var active):
            let sequenceNumber = active.nextConditionSequenceNumber
            active.nextConditionSequenceNumber += 1
            self = .init(state: .active(active))
            return sequenceNumber
        }
    }

    mutating func nextChildWorkflowSequenceNumber() -> UInt32 {
        switch consume self.state {
        case .active(var active):
            let sequenceNumber = active.nextChildWorkflowSequenceNumber
            active.nextChildWorkflowSequenceNumber += 1
            self = .init(state: .active(active))
            return sequenceNumber
        }
    }

    mutating func nextExternalSignalSequenceNumber() -> UInt32 {
        switch consume self.state {
        case .active(var active):
            let sequenceNumber = active.nextExternalSignalSequenceNumber
            active.nextExternalSignalSequenceNumber += 1
            self = .init(state: .active(active))
            return sequenceNumber
        }
    }

    mutating func updateRandomnessSeed(_ seed: UInt64) {
        switch consume self.state {
        case .active(var active):
            active.randomNumberGenerator = .init(seed: seed)
            self = .init(state: .active(active))
        }
    }

    mutating func generateNextRandomNumber() -> UInt64 {
        switch consume self.state {
        case .active(var active):
            let randomNumber = active.randomNumberGenerator.next()
            self = .init(state: .active(active))
            return randomNumber
        }
    }

    mutating func activate(with activation: Coresdk.WorkflowActivation.WorkflowActivation) {
        switch consume self.state {
        case .active(var active):
            active.isReplaying = activation.isReplaying
            active.now = activation.timestamp.date
            active.continueAsNewSuggested = activation.continueAsNewSuggested
            active.currentHistoryLength = Int(activation.historyLength)
            active.currentHistorySize = Int(activation.historySizeBytes)
            self = .init(state: .active(active))
        }
    }

    mutating func forceCancelOutstandingContinuations() {
        switch consume self.state {
        case .active(var active):
            let error = WorkflowRemovedFromCacheError()

            let activityContinuations = active.activityContinuations
            active.activityContinuations.removeAll()
            for continuation in activityContinuations {
                continuation.value.resume(throwing: error)
            }

            let waitConditionContinuations = active.waitConditionContinuations
            active.waitConditionContinuations.removeAll()
            for continuation in waitConditionContinuations {
                continuation.value.1?.resume(throwing: error)
            }

            let timerContinuations = active.timerContinuations
            active.timerContinuations.removeAll()
            for continuation in timerContinuations {
                continuation.value.resume(throwing: error)
            }

            let childWorkflowStartContinuations = active.childWorkflowStartContinuations
            active.childWorkflowStartContinuations.removeAll()
            for continuation in childWorkflowStartContinuations {
                continuation.value.1.resume(throwing: error)
            }

            let externalWorkflowSignalContinuations = active.externalWorkflowSignalContinuations
            active.externalWorkflowSignalContinuations.removeAll()
            for continuation in externalWorkflowSignalContinuations {
                continuation.value.resume(throwing: error)
            }

            self = .init(state: .active(active))
        }
    }

    @discardableResult
    mutating func patch(_ id: String, _ deprecated: Bool) -> Bool {
        switch consume self.state {
        case .active(var active):
            if let patched = active.patchesMemoized[id] {
                self = .init(state: .active(active))
                return patched
            }

            let patched = !active.isReplaying || active.patchesNotified.contains(id)
            active.patchesMemoized[id] = patched

            if patched {
                active.commands.append(
                    .with {
                        $0.setPatchMarker = .with {
                            $0.patchID = id
                            $0.deprecated = deprecated
                        }
                    }
                )
            }

            self = .init(state: .active(active))
            return patched
        }
    }

    mutating func notifyHasPatch(_ id: String) {
        switch consume self.state {
        case .active(var active):
            active.patchesNotified.insert(id)
            self = .init(state: .active(active))
        }
    }

    mutating func sleep(
        for duration: Duration,
        summary: TemporalPayload?,
        sequenceNumber: UInt32,
        continuation: CheckedContinuation<Void, any Error>
    ) {
        switch consume self.state {
        case .active(var active):
            active.commands.append(
                .with {
                    $0.startTimer = .with {
                        $0.seq = sequenceNumber
                        $0.startToFireTimeout = .with {
                            $0.seconds = duration.components.seconds
                            $0.nanos = Int32(duration.components.attoseconds / 1_000_000_000)
                        }
                    }

                    if let summary {
                        $0.userMetadata.summary = .init(temporalPayload: summary)
                    }
                }
            )
            active.timerContinuations[sequenceNumber] = continuation
            self = .init(state: .active(active))
        }
    }

    mutating func fireTimer(_ fireTimer: Coresdk.WorkflowActivation.FireTimer) -> CheckedContinuation<Void, any Error>? {
        switch consume self.state {
        case .active(var active):
            guard let continuation = active.timerContinuations.removeValue(forKey: fireTimer.seq) else {
                self = .init(state: .active(active))
                return nil  // this races against the timer/workflow being cancelled as part of the same activation.
            }

            self = .init(state: .active(active))
            return continuation
        }
    }

    mutating func cancelTimer(sequenceNumber: UInt32) -> CheckedContinuation<Void, any Error>? {
        switch consume self.state {
        case .active(var active):
            guard let continuation = active.timerContinuations.removeValue(forKey: sequenceNumber) else {
                self = .init(state: .active(active))
                return nil  // this races against the timer being fired as part of the same activation.
            }

            active.commands.append(
                .with {
                    $0.cancelTimer = .with {
                        $0.seq = sequenceNumber
                    }
                }
            )

            self = .init(state: .active(active))
            return continuation
        }
    }

    mutating func handlerStarted() {
        switch consume self.state {
        case .active(var active):
            active.numberOfActiveHandlers += 1
            self = .init(state: .active(active))
        }
    }

    mutating func handlerFinished() {
        switch consume self.state {
        case .active(var active):
            active.numberOfActiveHandlers -= 1
            self = .init(state: .active(active))
        }
    }

    func allHandlersFinished() -> Bool {
        switch self.state {
        case .active(let active):
            return active.numberOfActiveHandlers == 0
        }
    }

    mutating func condition(
        _ condition: @escaping () -> Bool
    ) -> UInt32 {
        switch consume self.state {
        case .active(var active):
            let id = active.nextConditionSequenceNumber
            active.nextConditionSequenceNumber += 1
            active.waitConditionContinuations[id] = (condition, nil)
            self = .init(state: .active(active))
            return id
        }
    }

    mutating func storeConditionContinuation(
        id: UInt32,
        continuation: CheckedContinuation<Void, any Error>
    ) -> CheckedContinuation<Void, any Error>? {
        switch consume self.state {
        case .active(var active):
            guard active.waitConditionContinuations[id] == nil else {
                active.waitConditionContinuations[id]?.1 = continuation
                self = .init(state: .active(active))
                return nil
            }
            // There is no condition stored which means we already got cancelled
            self = .init(state: .active(active))
            return continuation
        }
    }

    mutating func cancelConditionContinuation(
        id: UInt32
    ) -> CheckedContinuation<Void, any Error>? {
        switch consume self.state {
        case .active(var active):
            let continuation = active.waitConditionContinuations.removeValue(forKey: id)
            self = .init(state: .active(active))
            return continuation?.1
        }
    }

    mutating func scheduleActivityExecution(
        sequenceNumber: UInt32,
        activityType: String,
        options: ActivityExecutionOptions,
        workflowTaskQueue: String,
        headers: [String: TemporalPayload],
        input: [TemporalPayload],
        continuation: CheckedContinuation<Coresdk.ActivityResult.ActivityResolution, any Error>
    ) {
        switch consume self.state {
        case .active(var active):
            active.activityContinuations[sequenceNumber] = continuation
            active.commands.append(
                .with {
                    switch options {
                    case let .remote(activityOptions):
                        $0.scheduleActivity = .init(
                            id: sequenceNumber,
                            activityType: activityType,
                            workflowTaskQueue: workflowTaskQueue,
                            headers: headers,
                            input: input,
                            options: activityOptions
                        )
                    case let .local(localActivityOptions, attempt, originalScheduleTime):
                        $0.scheduleLocalActivity = .init(
                            id: sequenceNumber,
                            activityType: activityType,
                            headers: headers,
                            input: input,
                            options: localActivityOptions,
                            attempt: attempt,
                            originalScheduleTime: originalScheduleTime
                        )
                    }
                }
            )
            self = .init(state: .active(active))
        }
    }

    mutating func cancelActivity(sequenceNumber: UInt32, isLocal: Bool) {
        switch consume self.state {
        case .active(var active):
            guard active.activityContinuations[sequenceNumber] != nil else {
                // we know this is not called before the activity continuation is persisted, therefore, activity was reported as completed
                // in the same activation as the workflow was cancelled.
                self = .init(state: .active(active))
                return
            }

            active.commands.append(
                .with {
                    if isLocal {
                        $0.requestCancelLocalActivity = .with {
                            $0.seq = sequenceNumber
                        }
                    } else {
                        $0.requestCancelActivity = .with {
                            $0.seq = sequenceNumber
                        }
                    }
                }
            )

            self = .init(state: .active(active))
        }
    }

    mutating func resolveActivity(
        _ resolveActivity: Coresdk.WorkflowActivation.ResolveActivity
    ) -> CheckedContinuation<Coresdk.ActivityResult.ActivityResolution, any Error>? {
        switch consume self.state {
        case .active(var active):
            // If the continuation wasn't there it means it was already cancelled.
            let maybeContinuation = active.activityContinuations.removeValue(forKey: resolveActivity.seq)
            self = .init(state: .active(active))
            return maybeContinuation
        }
    }

    func conditions() -> [UInt32: () -> Bool] {
        switch self.state {
        case .active(let active):
            return active.waitConditionContinuations.mapValues { $0.0 }
        }
    }

    mutating func removeCondition(id: UInt32) -> CheckedContinuation<Void, any Error> {
        switch consume self.state {
        case .active(var active):
            let (_, continuation) = active.waitConditionContinuations.removeValue(forKey: id) ?? (nil, nil)
            guard let continuation else {
                // TODO: This might happen if the workflow worker gets cancelled while a workflow
                // is waiting for a condition and we then spin the workflow's executor again.
                fatalError("Internal inconsistency: No continuation found for wait condition with id \(id)")
            }
            self = .init(state: .active(active))
            return continuation
        }
    }

    mutating func queryFinished(id: String, temporalPayload: TemporalPayload) {
        switch consume self.state {
        case .active(var active):
            active.commands.append(
                .with {
                    $0.respondToQuery = .with {
                        $0.queryID = id
                        $0.succeeded = .with {
                            $0.response = .init(temporalPayload: temporalPayload)
                        }
                    }
                }
            )
            self = .init(state: .active(active))
        }
    }

    mutating func queryFailed(id: String, temporalFailure: TemporalFailure) {
        switch consume self.state {
        case .active(var active):
            active.commands.append(
                .with {
                    $0.respondToQuery = .with {
                        $0.queryID = id
                        $0.failed = .init(temporalFailure: temporalFailure)
                    }
                }
            )
            self = .init(state: .active(active))
        }
    }

    mutating func updateAccepted(id: String) {
        switch consume self.state {
        case .active(var active):
            active.commands.append(
                .with {
                    $0.updateResponse = .with {
                        $0.protocolInstanceID = id
                        $0.accepted = .init()
                    }
                }
            )
            self = .init(state: .active(active))
        }
    }

    mutating func updateCompleted(id: String, temporalPayload: TemporalPayload) {
        switch consume self.state {
        case .active(var active):
            active.commands.append(
                .with {
                    $0.updateResponse = .with {
                        $0.protocolInstanceID = id
                        $0.completed = .init(temporalPayload: temporalPayload)
                    }
                }
            )
            self = .init(state: .active(active))
        }
    }

    mutating func updateRejected(id: String, temporalFailure: TemporalFailure) {
        switch consume self.state {
        case .active(var active):
            active.commands.append(
                .with {
                    $0.updateResponse = .with {
                        $0.protocolInstanceID = id
                        $0.rejected = .init(temporalFailure: temporalFailure)
                    }
                }
            )
            self = .init(state: .active(active))
        }
    }

    mutating func startChildWorkflow(
        sequenceNumber: UInt32,
        namespace: String,
        taskQueue: String,
        workflowName: String,
        headers: [String: TemporalPayload],
        inputs: [TemporalPayload],
        childWorkflowOptions: ChildWorkflowOptions,
        memo: [String: TemporalPayload]?,
        state: UntypedChildWorkflowHandle.State,
        continuation: CheckedContinuation<(String, String), any Error>
    ) {
        switch consume self.state {
        case .active(var active):
            let workflowID = childWorkflowOptions.id ?? UUID.random(using: &active.randomNumberGenerator).uuidString
            let headers = active.headers.merging(headers) { $1 }
            active.commands.append(
                .with {
                    $0.startChildWorkflowExecution = .init(
                        sequenceNumber: sequenceNumber,
                        namespace: namespace,
                        workflowName: workflowName,
                        childWorkflowOptions: childWorkflowOptions,
                        generatedWorkflowID: workflowID,
                        taskQueue: taskQueue,
                        parentSearchAttributes: active.searchAttributes,
                        memo: memo,
                        headers: headers,
                        inputs: inputs
                    )
                }
            )
            active.childWorkflowStartContinuations[sequenceNumber] = (workflowID, continuation)
            active.childWorkflowResultStates[sequenceNumber] = state
            self = .init(state: .active(active))
        }
    }

    mutating func cancelChildWorkflow(sequenceNumber: UInt32) {
        switch consume self.state {
        case .active(var active):
            guard
                active.childWorkflowStartContinuations.contains(where: { $0.key == sequenceNumber })
                    || active.childWorkflowResultStates.contains(where: { $0.key == sequenceNumber })
            else {
                // this races against the workflow being resolved as part of the same continuation.
                self = .init(state: .active(active))
                return
            }

            active.commands.append(
                .with {
                    $0.cancelChildWorkflowExecution = .with {
                        $0.childWorkflowSeq = sequenceNumber
                    }
                }
            )

            self = .init(state: .active(active))
        }
    }

    mutating func removeStartChildWorkflowContinuation(
        sequenceNumber: UInt32
    ) -> (String, CheckedContinuation<(String, String), any Error>) {
        switch consume self.state {
        case .active(var active):
            guard let (workflowID, continuation) = active.childWorkflowStartContinuations.removeValue(forKey: sequenceNumber) else {
                fatalError("Internal inconsistency: No continuation found for \(sequenceNumber)")
            }

            self = .init(state: .active(active))
            return (workflowID, continuation)
        }
    }

    mutating func resolveChildWorkflowResult(
        sequenceNumber: UInt32
    ) -> UntypedChildWorkflowHandle.State {
        switch consume self.state {
        case .active(var active):
            guard let state = active.childWorkflowResultStates.removeValue(forKey: sequenceNumber) else {
                fatalError("Internal inconsistency: No state found for \(sequenceNumber)")
            }

            self = .init(state: .active(active))
            return state
        }
    }

    mutating func signalChildWorkflow(
        sequenceNumber: UInt32,
        childWorkflowID: String,
        signalName: String,
        headers: [String: TemporalPayload],
        inputs: [TemporalPayload],
        continuation: CheckedContinuation<Void, any Error>
    ) {
        switch consume self.state {
        case .active(var active):
            active.commands.append(
                .with {
                    $0.signalExternalWorkflowExecution = .with {
                        $0.seq = sequenceNumber
                        $0.childWorkflowID = childWorkflowID
                        $0.signalName = signalName
                        $0.args = inputs.map { .init(temporalPayload: $0) }
                        $0.headers = headers.mapValues { .init(temporalPayload: $0) }
                    }
                }
            )

            active.externalWorkflowSignalContinuations[sequenceNumber] = continuation

            self = .init(state: .active(active))
        }
    }

    mutating func cancelExternalSignalWorkflow(sequenceNumber: UInt32) {
        switch consume self.state {
        case .active(var active):
            active.commands.append(
                .with {
                    $0.cancelSignalWorkflow = .with {
                        $0.seq = sequenceNumber
                    }
                }
            )

            self = .init(state: .active(active))
        }
    }

    mutating func removeExternalWorkflowContinuation(
        sequenceNumber: UInt32
    ) -> CheckedContinuation<Void, any Error> {
        switch consume self.state {
        case .active(var active):
            guard let continuation = active.externalWorkflowSignalContinuations.removeValue(forKey: sequenceNumber) else {
                fatalError("Internal inconsistency: No continuation found for \(sequenceNumber)")
            }

            self = .init(state: .active(active))
            return continuation
        }
    }

    func isReplaying() -> Bool {
        switch state {
        case .active(let active): active.isReplaying
        }
    }

    func now() -> Date {
        switch state {
        case .active(let active): active.now
        }
    }

    func continueAsNewSuggested() -> Bool {
        switch state {
        case .active(let active): active.continueAsNewSuggested
        }
    }

    func currentHistorySize() -> Int {
        switch state {
        case .active(let active): active.currentHistorySize
        }
    }

    func currentHistoryLength() -> Int {
        switch state {
        case .active(let active): active.currentHistoryLength
        }
    }

    mutating func continueAsNew(_ continueAsNewError: ContinueAsNewError) {
        switch consume self.state {
        case .active(var active):
            active.commands.append(
                .with {
                    $0.continueAsNewWorkflowExecution = .init(continueAsNewError: continueAsNewError)
                }
            )
            self = .init(state: .active(active))
        }
    }

    mutating func cancelWorkflowExecution() {
        switch consume self.state {
        case .active(var active):
            active.commands.append(
                .with {
                    $0.cancelWorkflowExecution = .init()
                }
            )
            self = .init(state: .active(active))
        }
    }

    // MARK: Memo

    func memo() -> [String: TemporalRawValue] {
        switch self.state {
        case .active(let active):
            return active.memo
        }
    }

    mutating func upsertMemo(_ memo: [String: TemporalRawValue?]) {
        switch consume self.state {
        case .active(var active):
            for (key, value) in memo {
                guard let value else {
                    active.memo[key] = nil
                    continue
                }
                active.memo[key] = value
            }
            active.commands.append(
                .with {
                    $0.modifyWorkflowProperties = .with {
                        $0.upsertedMemo = .with {
                            $0.fields = memo.mapValues { $0.flatMap { .init(temporalPayload: $0.payload) } ?? .init() }
                        }
                    }
                }
            )
            self = .init(state: .active(active))
        }
    }

    mutating func setMemo(_ memo: [String: TemporalRawValue]) {
        switch consume self.state {
        case .active(var active):
            active.memo = memo
            self = .init(state: .active(active))
        }
    }

    // MARK: Search Attributes

    mutating func setSearchAttributes(_ searchAttributes: SearchAttributeCollection) {
        switch consume state {
        case .active(var active):
            active.searchAttributes = searchAttributes
            self = .init(state: .active(active))
        }
    }

    func searchAttributes() -> SearchAttributeCollection {
        switch state {
        case .active(let active):
            return active.searchAttributes
        }
    }

    mutating func upsertSearchAttributes(_ searchAttributes: SearchAttributeCollection) {
        switch consume state {
        case .active(var active):
            active.searchAttributes.upsert(with: searchAttributes)
            active.commands.append(
                .with {
                    $0.upsertWorkflowSearchAttributes = .with {
                        $0.searchAttributes = Api.Common.V1.SearchAttributes(searchAttributes).indexedFields
                    }
                }
            )
            self = .init(state: .active(active))
        }
    }

    // MARK: Current Details

    func currentDetails() -> String? {
        switch state {
        case .active(let active): active.currentDetails
        }
    }

    mutating func setCurrentDetails(_ currentDetails: String?) {
        switch consume state {
        case .active(var active):
            active.currentDetails = currentDetails
            self = .init(state: .active(active))
        }
    }

    mutating func workflowFinished(temporalPayload: TemporalPayload) {
        switch consume self.state {
        case .active(var active):
            active.commands.append(
                .with {
                    $0.completeWorkflowExecution = .with {
                        $0.result = .init(temporalPayload: temporalPayload)
                    }
                }
            )
            self = .init(state: .active(active))
        }
    }

    mutating func workflowFinished(temporalFailure: TemporalFailure) {
        switch consume self.state {
        case .active(var active):
            active.commands.append(
                .with {
                    $0.failWorkflowExecution = .with {
                        $0.failure = .init(temporalFailure: temporalFailure)
                    }
                }
            )
            self = .init(state: .active(active))
        }
    }

    mutating func workflowTaskFailed(temporalFailure: TemporalFailure) {
        switch consume self.state {
        case .active(var active):
            active.activationFailure = temporalFailure
            self = .init(state: .active(active))
        }
    }

    enum CommandsAction {
        case sendCommands([Coresdk.WorkflowCommands.WorkflowCommand])
        case failActivation(TemporalFailure)
    }
    mutating func commands() -> CommandsAction {
        switch consume self.state {
        case .active(var active):
            guard let activationFailure = active.activationFailure else {
                let commands = active.commands
                active.commands = []
                self = .init(state: .active(active))
                return .sendCommands(commands)
            }
            active.activationFailure = nil
            self = .init(state: .active(active))
            return .failActivation(activationFailure)
        }
    }
}
