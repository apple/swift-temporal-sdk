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

import Tracing

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

// Client Outbound interceptor attributes
extension Span {
    // MARK: StartWorkflow

    func setStartWorkflowRequestSpanAttributes<each Input>(input: StartWorkflowInput<repeat each Input>) {
        // The name of the workflow to start
        self.attributes[TemporalTracingKeys.workflowName] = input.name
        // The unique workflow identifier
        self.attributes[TemporalTracingKeys.workflowId] = input.options.id
        // The task queue to run the workflow on
        self.attributes[TemporalTracingKeys.workflowTaskQueue] = input.options.taskQueue
        // Total workflow execution timeout including retries and continue as new.
        if let timeout = input.options.executionTimeOut?.description {
            self.attributes[TemporalTracingKeys.workflowExecutionTimeout] = timeout
        }
        // The workflow's retry policy.
        if let retryPolicy = input.options.retryPolicy {
            self.attributes[TemporalTracingKeys.workflowRetryPolicyMaximumAttempts] = retryPolicy.maximumAttempts.description
            self.attributes[TemporalTracingKeys.workflowRetryPolicyBackOffCoefficient] = retryPolicy.backoffCoefficient.description
            if let initialInterval = retryPolicy.initialInterval {
                self.attributes[TemporalTracingKeys.workflowRetryPolicyInitialInterval] = initialInterval.description
            }
            if let maximumInterval = retryPolicy.maximumInterval {
                self.attributes[TemporalTracingKeys.workflowRetryPolicyMaximumInterval] = maximumInterval.description
            }
        }
        // The search attributes for the workflow.
        // swift-format-ignore: ReplaceForEachWithForLoop
        input.options.searchAttributes?.forEach { key, value in
            if let value {
                self.attributes["\(TemporalTracingKeys.workflowSearchAttributesPrefix)\(key.name) (\(key.type.indexedValueTypeString))"] = "\(value)"
            }
        }
        // The workflow's memo.
        // swift-format-ignore: ReplaceForEachWithForLoop
        input.options.memo?.forEach { key, value in
            self.attributes["\(TemporalTracingKeys.workflowMemoPrefix)\(key)"] = "\(value)"
        }
        // The headers to include in the request.
        // swift-format-ignore: ReplaceForEachWithForLoop
        input.headers.forEach { key, value in
            self.attributes["\(TemporalTracingKeys.workflowHeadersPrefix)\(key)"] = "\(value)"
        }

        // We do not record the input
    }

    func setStartWorkflowResponseSpanAttributes(response: UntypedWorkflowHandle) {
        // Workflow ID already set on the request side
        if let runId = response.runID {
            self.attributes[TemporalTracingKeys.workflowRunId] = runId
        }

        if let firstExecutionRunId = response.firstExecutionRunID {
            self.attributes[TemporalTracingKeys.workflowFirstExecutionRunId] = firstExecutionRunId
        }

        if let resultRunId = response.resultRunID {
            self.attributes[TemporalTracingKeys.workflowResultRunId] = resultRunId
        }
    }

    // MARK: Signal Workflow

    func setSignalWorkflowSpanAttributes<each Input>(input: SignalWorkflowInput<repeat each Input>) {
        // The unique workflow identifier
        self.attributes[TemporalTracingKeys.workflowId] = input.id

        if let runID = input.runID {
            self.attributes[TemporalTracingKeys.workflowRunId] = runID
        }

        // The signal's name
        self.attributes[TemporalTracingKeys.workflowSignalName] = input.name

        // The headers to include in the request.
        // swift-format-ignore: ReplaceForEachWithForLoop
        input.headers.forEach { key, value in
            self.attributes["\(TemporalTracingKeys.workflowHeadersPrefix)\(key)"] = "\(value)"
        }

        // We do not record the input
    }

    // MARK: Query Workflow

    func setQueryWorkflowSpanAttributes<each Input>(input: QueryWorkflowInput<repeat each Input>) {
        // The unique workflow identifier
        self.attributes[TemporalTracingKeys.workflowId] = input.id

        if let runID = input.runID {
            self.attributes[TemporalTracingKeys.workflowRunId] = runID
        }

        // The query's name
        self.attributes[TemporalTracingKeys.workflowQueryName] = input.queryName

        // The condition under which workflow state the query should be rejected
        if let rejectionCondition = input.rejectionCondition {
            self.attributes[TemporalTracingKeys.workflowQueryRejectCondition] = rejectionCondition.description
        }
        // The headers to include in the request.
        // swift-format-ignore: ReplaceForEachWithForLoop
        input.headers.forEach { key, value in
            self.attributes["\(TemporalTracingKeys.workflowHeadersPrefix)\(key)"] = "\(value)"
        }

        // We do not record the input
    }

    // MARK: Start Workflow Update

    func setStartWorkflowUpdateRequestSpanAttributes<each Input>(input: StartWorkflowUpdateInput<repeat each Input>) {
        // The unique workflow identifier
        self.attributes[TemporalTracingKeys.workflowId] = input.id

        if let runID = input.runID {
            self.attributes[TemporalTracingKeys.workflowRunId] = runID
        }

        // The update identifier
        self.attributes[TemporalTracingKeys.workflowUpdateId] = input.updateID

        // The update name
        self.attributes[TemporalTracingKeys.workflowUpdateName] = input.updateName

        // The first execution run identifier
        if let firstExecutionRunId = input.firstExecutionRunID {
            self.attributes[TemporalTracingKeys.workflowFirstExecutionRunId] = firstExecutionRunId
        }

        // The headers to include in the request.
        // swift-format-ignore: ReplaceForEachWithForLoop
        input.headers.forEach { key, value in
            self.attributes["\(TemporalTracingKeys.workflowHeadersPrefix)\(key)"] = "\(value)"
        }

        // We do not record the input
    }

    func setStartWorkflowUpdateResponseSpanAttributes(response: UntypedWorkflowUpdateHandle) {
        // Update ID recorded in request

        // Workflow run ID used for updates if present to ensure a very specific run to call
        if let workflowRunId = response.workflowRunID {
            self.attributes[TemporalTracingKeys.workflowRunId] = workflowRunId
        }
    }

    // MARK: Describe Workflow

    func setDescribeWorkflowRequestSpanAttributes(input: DescribeWorkflowInput) {
        // The unique workflow identifier
        self.attributes[TemporalTracingKeys.workflowId] = input.id

        if let runID = input.runID {
            self.attributes[TemporalTracingKeys.workflowRunId] = runID
        }
    }

    func setDescribeWorkflowResponseSpanAttributes(response: WorkflowExecutionDescription) {
        // Update ID recorded in request

        // The name of the workflow type for this workflow execution.
        self.attributes[TemporalTracingKeys.workflowType] = response.execution.workflowType

        // Workflow run ID used for updates if present to ensure a very specific run to call
        self.attributes[TemporalTracingKeys.workflowRunId] = response.execution.runID

        // The task queue for the workflow execution.
        self.attributes[TemporalTracingKeys.workflowTaskQueue] = response.execution.taskQueue

        // The ID for the parent workflow execution, if this was started as a child.
        if let parentId = response.execution.parentWorkflowID {
            self.attributes[TemporalTracingKeys.workflowParentId] = parentId
        }

        // The run ID for the parent workflow execution, if this was started as a child.
        if let parentRunId = response.execution.parentRunID {
            self.attributes[TemporalTracingKeys.workflowParentRunId] = parentRunId
        }

        // When the workflow execution was created
        self.attributes[TemporalTracingKeys.workflowStartTime] = response.execution.startTime.description
    }

    // MARK: Cancel Workflow

    func setCancelWorkflowSpanAttributes(input: CancelWorkflowInput) {
        // The unique workflow identifier
        self.attributes[TemporalTracingKeys.workflowId] = input.id

        if let runID = input.runID {
            self.attributes[TemporalTracingKeys.workflowRunId] = runID
        }

        if let firstExecutionRunID = input.firstExecutionRunID {
            self.attributes[TemporalTracingKeys.workflowFirstExecutionRunId] = firstExecutionRunID
        }
    }

    // MARK: Terminate workflow

    func setTerminateWorkflowSpanAttributes<each Detail>(input: TerminateWorkflowInput<repeat each Detail>) {
        self.attributes[TemporalTracingKeys.workflowId] = input.id

        if let runID = input.runID {
            self.attributes[TemporalTracingKeys.workflowRunId] = runID
        }

        if let firstExecutionRunID = input.firstExecutionRunID {
            self.attributes[TemporalTracingKeys.workflowFirstExecutionRunId] = firstExecutionRunID
        }

        if let reason = input.reason {
            self.attributes[TemporalTracingKeys.workflowTerminationReason] = reason
        }
    }

    // MARK: Fetch workflow history

    func setFetchWorkflowHistoryRequestSpanAttributes(input: FetchWorkflowHistoryEventsInput) {
        self.attributes[TemporalTracingKeys.workflowId] = input.id
        if let runId = input.runID {
            self.attributes[TemporalTracingKeys.workflowRunId] = runId
        }
        self.attributes[TemporalTracingKeys.workflowEventHistorySkipArchival] = input.skipArchival
        self.attributes[TemporalTracingKeys.workflowEventHistoryWaitNewEvent] = input.waitNewEvent
        self.attributes[TemporalTracingKeys.workflowEventHistoryFilterType] = input.eventFilterType.description
    }

    func setFetchWorkflowHistoryResponseSpanAttributes(count: Int) {
        self.attributes[TemporalTracingKeys.workflowEventHistoryCount] = count
    }

    // MARK: List Workflows

    func setListWorkflowsRequestSpanAttributes(query: String, limit: Int?) {
        self.attributes[TemporalTracingKeys.scheduleListQuery] = query

        if let limit {
            self.attributes[TemporalTracingKeys.workflowListLimit] = limit
        }
    }

    // MARK: Count Workflows

    func setCountWorkflowsRequestSpanAttributes(query: String) {
        self.attributes[TemporalTracingKeys.workflowCountQuery] = query
    }

    func setCountWorkflowsResponseSpanAttributes(count: Int) {
        self.attributes[TemporalTracingKeys.workflowCountNumber] = count
    }

    // MARK: Schedules

    func setCreateScheduleRequestSpanAttributes<Workflow>(input: CreateScheduleInput<Workflow>) {
        self.attributes[TemporalTracingKeys.scheduleId] = input.id
        if let options = input.options {
            // swift-format-ignore: ReplaceForEachWithForLoop
            options.backfills.forEach { backfill in
                self.attributes[TemporalTracingKeys.scheduleBackfillStartAt] = backfill.startAt.description
                self.attributes[TemporalTracingKeys.scheduleBackfillEndAt] = backfill.endAt.description
                if let overlap = backfill.overlap {
                    self.attributes[TemporalTracingKeys.scheduleBackfillOverlapPolicy] = overlap.description
                }
            }

            self.attributes[TemporalTracingKeys.scheduleTriggerImmediately] = options.triggerImmediately

            // The search attributes of the schedule.
            // swift-format-ignore: ReplaceForEachWithForLoop
            options.searchAttributes?.forEach { key, value in
                if let value {
                    self.attributes["\(TemporalTracingKeys.scheduleSearchAttributesPrefix)\(key.name) (\(key.type.indexedValueTypeString))"] =
                        "\(value)"
                }
            }
        }

        self.attributes[TemporalTracingKeys.scheduleStateNote] = input.schedule.state.note
        self.attributes[TemporalTracingKeys.scheduleStatePaused] = input.schedule.state.paused ? "Paused" : "Running"
        self.attributes[TemporalTracingKeys.scheduleStateLimitedActions] = input.schedule.state.limitedActions
        self.attributes[TemporalTracingKeys.scheduleStateRemainingActions] = input.schedule.state.remainingActions
        if case let .startWorkflow(workflow) = input.schedule.action {
            self.attributes[TemporalTracingKeys.workflowId] = workflow.options.id
            self.attributes[TemporalTracingKeys.workflowTaskQueue] = workflow.options.taskQueue
            if let executionTimeout = workflow.options.executionTimeOut {
                self.attributes[TemporalTracingKeys.workflowExecutionTimeout] = executionTimeout.description
            }
            if let retryPolicy = workflow.options.retryPolicy {
                self.attributes[TemporalTracingKeys.workflowRetryPolicyMaximumAttempts] = retryPolicy.maximumAttempts
                self.attributes[TemporalTracingKeys.workflowRetryPolicyBackOffCoefficient] = retryPolicy.backoffCoefficient
                if let initialInterval = retryPolicy.initialInterval {
                    self.attributes[TemporalTracingKeys.workflowRetryPolicyInitialInterval] = initialInterval.description
                }
                if let maximumInterval = retryPolicy.maximumInterval {
                    self.attributes[TemporalTracingKeys.workflowRetryPolicyMaximumInterval] = maximumInterval.description
                }
            }
            // The search attributes for the workflow.
            // swift-format-ignore: ReplaceForEachWithForLoop
            workflow.options.searchAttributes?.forEach { key, value in
                if let value {
                    self.attributes["\(TemporalTracingKeys.workflowSearchAttributesPrefix)\(key.name) (\(key.type.indexedValueTypeString))"] =
                        "\(value)"
                }
            }
        }

        self.attributes[TemporalTracingKeys.schedulePolicyCatchupWindow] = input.schedule.policy.catchupWindow.description
        self.attributes[TemporalTracingKeys.schedulePolicyOverlap] = input.schedule.policy.overlap.description
        self.attributes[TemporalTracingKeys.schedulePolicyPauseOnFailure] = input.schedule.policy.pauseOnFailure

        if let startAt = input.schedule.specification.startAt {
            self.attributes[TemporalTracingKeys.scheduleSpecificationStartAt] = startAt.description
        }
        if let endAt = input.schedule.specification.endAt {
            self.attributes[TemporalTracingKeys.scheduleSpecificationEndAt] = endAt.description
        }
        if let jitter = input.schedule.specification.jitter {
            self.attributes[TemporalTracingKeys.scheduleSpecificationJitter] = jitter.description
        }
        if let timeZoneName = input.schedule.specification.timeZoneName {
            self.attributes[TemporalTracingKeys.scheduleSpecificationTimezoneName] = timeZoneName
        }
    }

    func setListSchedulesRequestSpanAttributes(query: String?) {
        if let query {
            self.attributes[TemporalTracingKeys.scheduleListQuery] = query
        }
    }

    func setBackfillScheduleSpanAttributes(scheduleId: String, backfills: [ScheduleBackfill]) {
        self.attributes[TemporalTracingKeys.scheduleId] = scheduleId
        // swift-format-ignore: ReplaceForEachWithForLoop
        backfills.forEach { backfill in
            self.attributes[TemporalTracingKeys.scheduleBackfillStartAt] = backfill.startAt.description
            self.attributes[TemporalTracingKeys.scheduleBackfillEndAt] = backfill.endAt.description
            if let overlap = backfill.overlap {
                self.attributes[TemporalTracingKeys.scheduleBackfillOverlapPolicy] = overlap.description
            }
        }
    }

    func setDeleteScheduleSpanAttributes(scheduleId: String) {
        self.attributes[TemporalTracingKeys.scheduleId] = scheduleId
    }

    func setDescribeScheduleRequestSpanAttributes(scheduleId: String) {
        self.attributes[TemporalTracingKeys.scheduleId] = scheduleId
    }

    func setDescribeScheduleResponseSpanAttributes<Workflow>(response: ScheduleDescription<Workflow>) {
        self.attributes[TemporalTracingKeys.scheduleStateNote] = response.schedule.state.note
        self.attributes[TemporalTracingKeys.scheduleStatePaused] = response.schedule.state.paused ? "Paused" : "Running"
        self.attributes[TemporalTracingKeys.scheduleStateLimitedActions] = response.schedule.state.limitedActions
        self.attributes[TemporalTracingKeys.scheduleStateRemainingActions] = response.schedule.state.remainingActions
        self.attributes[TemporalTracingKeys.scheduleConflictToken] = response.conflictToken.base64EncodedString()
        if case let .startWorkflow(workflow) = response.schedule.action {
            self.attributes[TemporalTracingKeys.workflowId] = workflow.options.id
            self.attributes[TemporalTracingKeys.workflowTaskQueue] = workflow.options.taskQueue
            if let executionTimeout = workflow.options.executionTimeOut {
                self.attributes[TemporalTracingKeys.workflowExecutionTimeout] = executionTimeout.description
            }
            if let retryPolicy = workflow.options.retryPolicy {
                self.attributes[TemporalTracingKeys.workflowRetryPolicyMaximumAttempts] = retryPolicy.maximumAttempts
                self.attributes[TemporalTracingKeys.workflowRetryPolicyBackOffCoefficient] = retryPolicy.backoffCoefficient
                if let initialInterval = retryPolicy.initialInterval {
                    self.attributes[TemporalTracingKeys.workflowRetryPolicyInitialInterval] = initialInterval.description
                }
                if let maximumInterval = retryPolicy.maximumInterval {
                    self.attributes[TemporalTracingKeys.workflowRetryPolicyMaximumInterval] = maximumInterval.description
                }
            }
            // The search attributes for the workflow.
            // swift-format-ignore: ReplaceForEachWithForLoop
            workflow.options.searchAttributes?.forEach { key, value in
                if let value {
                    self.attributes["\(TemporalTracingKeys.workflowSearchAttributesPrefix)\(key.name) (\(key.type.indexedValueTypeString))"] =
                        "\(value)"
                }
            }
        }

        // The search attributes of the schedule.
        // swift-format-ignore: ReplaceForEachWithForLoop
        response.searchAttributes?.forEach { key, value in
            if let value {
                self.attributes["\(TemporalTracingKeys.scheduleSearchAttributesPrefix)\(key.name) (\(key.type.indexedValueTypeString))"] = "\(value)"
            }
        }

        self.attributes[TemporalTracingKeys.schedulePolicyCatchupWindow] = response.schedule.policy.catchupWindow.description
        self.attributes[TemporalTracingKeys.schedulePolicyOverlap] = response.schedule.policy.overlap.description
        self.attributes[TemporalTracingKeys.schedulePolicyPauseOnFailure] = response.schedule.policy.pauseOnFailure

        if let startAt = response.schedule.specification.startAt {
            self.attributes[TemporalTracingKeys.scheduleSpecificationStartAt] = startAt.description
        }
        if let endAt = response.schedule.specification.endAt {
            self.attributes[TemporalTracingKeys.scheduleSpecificationEndAt] = endAt.description
        }
        if let jitter = response.schedule.specification.jitter {
            self.attributes[TemporalTracingKeys.scheduleSpecificationJitter] = jitter.description
        }
        if let timeZoneName = response.schedule.specification.timeZoneName {
            self.attributes[TemporalTracingKeys.scheduleSpecificationTimezoneName] = timeZoneName
        }

        self.attributes[TemporalTracingKeys.scheduleInfoCreatedAt] = response.info.createdAt.description
        if let lastUpdatedAt = response.info.lastUpdatedAt {
            self.attributes[TemporalTracingKeys.scheduleInfoLastUpdatedAt] = lastUpdatedAt.description
        }
        self.attributes[TemporalTracingKeys.scheduleInfoNextActionTimes] = response.info.nextActionTimes.map { $0.ISO8601Format() }.joined(
            separator: ", "
        )
        self.attributes[TemporalTracingKeys.scheduleInfoNumActions] = response.info.numActions
        self.attributes[TemporalTracingKeys.scheduleInfoNumActionsBufferDropped] = response.info.numActionsBufferDropped
        self.attributes[TemporalTracingKeys.scheduleInfoNumActionsInBuffer] = response.info.numActionsInBuffer
        self.attributes[TemporalTracingKeys.scheduleInfoNumActionsMissedCatchupWindow] = response.info.numActionsMissedCatchupWindow
        self.attributes[TemporalTracingKeys.scheduleInfoNumActionsSkippedOverlap] = response.info.numActionsSkippedOverlap
    }

    func setPauseScheduleSpanAttributes(scheduleId: String, note: String?) {
        self.attributes[TemporalTracingKeys.scheduleId] = scheduleId
        if let note {
            self.attributes[TemporalTracingKeys.schedulePatchNote] = note
        }
        self.attributes[TemporalTracingKeys.schedulePatchAction] = "pause"
    }

    func setTriggerScheduleSpanAttributes(scheduleId: String, overlap: ScheduleOverlapPolicy?) {
        self.attributes[TemporalTracingKeys.scheduleId] = scheduleId
        if let overlap {
            self.attributes[TemporalTracingKeys.schedulePatchOverlapPolicy] = overlap.description
        }
        self.attributes[TemporalTracingKeys.schedulePatchAction] = "trigger"
    }

    func setUnpauseScheduleSpanAttributes(scheduleId: String, note: String?) {
        self.attributes[TemporalTracingKeys.scheduleId] = scheduleId
        if let note {
            self.attributes[TemporalTracingKeys.schedulePatchNote] = note
        }
        self.attributes[TemporalTracingKeys.schedulePatchAction] = "unpause"
    }

    func setUpdateScheduleSpanAttributes(scheduleId: String) {
        self.attributes[TemporalTracingKeys.scheduleId] = scheduleId
    }

    // MARK: Async Activities

    func setHeartbeatAsyncActivity(input: HeartbeatAsyncActivityInput) {
        self.setActivityReference(reference: input.activity)

        if let details = input.options?.details {
            self.attributes[TemporalTracingKeys.activityHeartbeatDetails] = details.map { "\($0)" }.joined(separator: "\n")
        }
    }

    func setCompleteAsyncActivity<Result>(input: CompleteAsyncActivityInput<Result>) {
        self.setActivityReference(reference: input.activity)
    }

    func setFailAsyncActivity(input: FailAsyncActivityInput) {
        self.setActivityReference(reference: input.activity)
        self.attributes[TemporalTracingKeys.activityFailCause] = "\(input.error)"

        if let details = input.options?.lastHeartbeatDetails {
            self.attributes[TemporalTracingKeys.activityHeartbeatLastDetails] = details.map { "\($0)" }.joined(separator: "\n")
        }
    }

    func setReportCancellationAsyncActivity(input: ReportCancellationAsyncActivityInput) {
        self.setActivityReference(reference: input.activity)

        if let details = input.options?.details {
            self.attributes[TemporalTracingKeys.activityHeartbeatDetails] = details.map { "\($0)" }.joined(separator: "\n")
        }
    }

    private func setActivityReference(reference: AsyncActivityHandle.Reference) {
        switch reference {
        case .id(let workflowId, let runId, let activityId):
            self.attributes[TemporalTracingKeys.workflowId] = workflowId
            self.attributes[TemporalTracingKeys.workflowRunId] = runId
            self.attributes[TemporalTracingKeys.activityID] = activityId
        case .taskToken(let taskToken):
            self.attributes[TemporalTracingKeys.activityTaskToken] = String(bytes: taskToken.bytes, encoding: .utf8)
        }
    }
}
