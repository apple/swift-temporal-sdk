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

public enum WorkflowTaskFailedCause: Hashable, Sendable {
    case unspecified

    /// Between starting and completing the workflow task (with a workflow completion command), some
    /// new command (like a signal) was processed into workflow history. The outstanding task will be
    /// failed with this reason, and a worker must pick up a new task.
    case unhandledCommand
    case badScheduleActivityAttributes
    case badRequestCancelActivityAttributes
    case badStartTimerAttributes
    case badCancelTimerAttributes
    case badRecordMarkerAttributes
    case badCompleteWorkflowExecutionAttributes
    case badFailWorkflowExecutionAttributes
    case badCancelWorkflowExecutionAttributes
    case badRequestCancelExternalWorkflowExecutionAttributes
    case badContinueAsNewAttributes
    case startTimerDuplicateID

    /// The worker wishes to fail the task and have the next one be generated on a normal, not sticky
    /// queue. Generally workers should prefer to use the explicit `ResetStickyTaskQueue` RPC call.
    case resetStickyTaskQueue
    case workflowWorkerUnhandledFailure
    case badSignalWorkflowExecutionAttributes
    case badStartChildExecutionAttributes
    case forceCloseCommand
    case failoverCloseCommand
    case badSignalInputSize
    case resetWorkflow
    case badBinary
    case scheduleActivityDuplicateID
    case badSearchAttributes

    /// The worker encountered a mismatch while replaying history between what was expected, and
    /// what the workflow code actually did.
    case nonDeterministicError
    case badModifyWorkflowPropertiesAttributes

    /// We send the below error codes to users when their requests would violate a size constraint
    /// of their workflow. We do this to ensure that the state of their workflow does not become too
    /// large because that can cause severe performance degradation. You can modify the thresholds for
    /// each of these errors within your dynamic config.
    ///
    /// Spawning a new child workflow would cause this workflow to exceed its limit of pending child
    /// workflows.
    case pendingChildWorkflowsLimitExceeded

    /// Starting a new activity would cause this workflow to exceed its limit of pending activities
    /// that we track.
    case pendingActivitiesLimitExceeded

    /// A workflow has a buffer of signals that have not yet reached their destination. We return this
    /// error when sending a new signal would exceed the capacity of this buffer.
    case pendingSignalsLimitExceeded

    /// Similarly, we have a buffer of pending requests to cancel other workflows. We return this error
    /// when our capacity for pending cancel requests is already reached.
    case pendingRequestCancelLimitExceeded

    /// Workflow execution update message (update.Acceptance, update.Rejection, or update.Response)
    /// has wrong format, or missing required fields.
    case badUpdateWorkflowExecutionMessage

    /// Similar to WORKFLOW_TASK_FAILED_CAUSE_UNHANDLED_COMMAND, but for updates.
    case unhandledUpdate

    /// A workflow task completed with an invalid ScheduleNexusOperation command.
    case badScheduleNexusOperationAttributes

    /// A workflow task completed requesting to schedule a Nexus Operation exceeding the server configured limit.
    case pendingNexusOperationsLimitExceeded

    /// A workflow task completed with an invalid RequestCancelNexusOperation command.
    case badRequestCancelNexusOperationAttributes

    /// A workflow task completed requesting a feature that's disabled on the server (either system wide or - typically -
    /// for the workflow's namespace).
    /// Check the workflow task failure message for more information.
    case featureDisabled

    /// A workflow task failed because a grpc message was too large.
    case grpcMessageTooLarge
}
