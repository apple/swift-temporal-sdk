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

/// Attribute keys required for tracing metadata in the spans.
package enum TemporalTracingKeys: Hashable, Sendable {
    package static let workflowName = "temporal.workflow.name"
    package static let workflowId = "temporal.workflow.id"
    package static let workflowType = "temporal.workflow.type"
    package static let workflowTaskQueue = "temporal.workflow.taskqueue"
    package static let workflowExecutionTimeout = "temporal.workflow.execution-timeout"
    package static let workflowRetryPolicyInitialInterval = "temporal.workflow.retry-policy.initial-interval"
    package static let workflowRetryPolicyMaximumAttempts = "temporal.workflow.retry-policy.maximum-attempts"
    package static let workflowRetryPolicyMaximumInterval = "temporal.workflow.retry-policy.maximum-interval"
    package static let workflowRetryPolicyBackOffCoefficient = "temporal.workflow.retry-policy.backoff-coefficient"
    package static let workflowRunId = "temporal.workflow.run-id"
    package static let workflowFirstExecutionRunId = "temporal.workflow.run-id-first-execution"
    package static let workflowResultRunId = "temporal.workflow.run-id-result"
    package static let workflowSignalName = "temporal.workflow.signal-name"
    package static let workflowQueryName = "temporal.workflow.query-name"
    package static let workflowQueryRejectCondition = "temporal.workflow.query-reject-condition"
    package static let workflowUpdateId = "temporal.workflow.update-id"
    package static let workflowUpdateName = "temporal.workflow.update-name"
    package static let workflowParentId = "temporal.workflow.parent.id"
    package static let workflowParentRunId = "temporal.workflow.parent.run-id"
    package static let workflowStartTime = "temporal.workflow.start-time"
    package static let workflowTerminationReason = "temporal.workflow.termination.reason"

    package static let workflowSearchAttributesPrefix = "temporal.workflow.search-attributes."
    package static let workflowMemoPrefix = "temporal.workflow.memo."
    package static let workflowHeadersPrefix = "temporal.workflow.headers."

    package static let workflowAttempt = "temporal.workflow.attempt"
    package static let workflowContinuedRunId = "temporal.workflow.continued-run-id"
    package static let workflowNamespace = "temporal.workflow.namespace"
    package static let workflowCronSchedule = "temporal.workflow.cron-schedule"
    package static let workflowRunTimeout = "temporal.workflow.run-timeout"
    package static let workflowTaskTimeout = "temporal.workflow.task-timeout"
    package static let workflowLastFailure = "temporal.workflow.last-failure"
    package static let workflowParentNamespace = "temporal.workflow.parent.namespace"
    package static let workflowQueryId = "temporal.workflow.query-id"

    package static let workflowParentClosePolicy = "temporal.workflow.parent.close-policy"
    package static let workflowIdReusePolicy = "temporal.workflow.id-reuse-policy"
    package static let workflowCancellationType = "temporal.workflow.cancellation-type"
    package static let workflowVersioningIntent = "temporal.workflow.versioning-intent"
    package static let workflowSleepDuration = "temporal.workflow.sleep.duration"
    package static let workflowSleepSummary = "temporal.workflow.sleep.summary"

    package static let workflowCountQuery = "temporal.workflow.count.query"
    package static let workflowCountNumber = "temporal.workflow.count"

    package static let workflowListQuery = "temporal.workflow.list.query"
    package static let workflowListLimit = "temporal.workflow.list.limit"

    package static let workflowEventHistoryCount = "temporal.workflow.event-history.count"
    package static let workflowEventHistorySkipArchival = "temporal.workflow.event-history.skip-archival"
    package static let workflowEventHistoryWaitNewEvent = "temporal.workflow.event-history.wait-new-event"
    package static let workflowEventHistoryFilterType = "temporal.workflow.event-history.filter-type"

    package static let workflowContinueAsNewExceptionMessage = "temporal.workflow.continue-as-new.exception.message"
    package static let workflowContinueAsNewExceptionType = "temporal.workflow.continue-as-new.exception.type"
    package static let workflowContinueAsNewExceptionStackTrace = "temporal.workflow.continue-as-new.exception.stacktrace"

    package static let activityName = "temporal.activity.name"
    package static let activityID = "temporal.activity.id"
    package static let activityDisableEagerExecution = "temporal.activity.disable-eager-execution"
    package static let activityCancellationType = "temporal.activity.cancellation-type"
    package static let activityHeartbeatTimeout = "temporal.activity.heartbeat-timeout"
    package static let activityScheduleToCloseTimeout = "temporal.activity.schedule-to-close-timeout"
    package static let activityScheduleToStartTimeout = "temporal.activity.schedule-to-start-timeout"
    package static let activityStartToCloseTimeout = "temporal.activity.start-to-close-timeout"
    package static let activityTaskQueue = "temporal.activity.task-queue"
    package static let activityRetryPolicyMaximumAttempts = "temporal.activity.retry-policy.maximum-attempts"
    package static let activityRetryPolicyBackoffCoefficient = "temporal.activity.retry-policy.backoff-coefficient"
    package static let activityRetryPolicyInitialInterval = "temporal.activity.retry-policy.initial-interval"
    package static let activityRetryPolicyMaximumInterval = "temporal.activity.retry-policy.maximum-interval"
    package static let activityVersioningIntent = "temporal.activity.versioning-intent"

    package static let scheduleId = "temporal.schedule.id"
    package static let schedulePatchNote = "temporal.schedule.patch.note"
    package static let schedulePatchAction = "temporal.schedule.patch.action"
    package static let schedulePatchOverlapPolicy = "temporal.schedule.patch.overlap-policy"
    package static let scheduleStateNote = "temporal.schedule.state.note"
    package static let scheduleStatePaused = "temporal.schedule.state.paused"
    package static let scheduleStateLimitedActions = "temporal.schedule.state.limited-actions"
    package static let scheduleStateRemainingActions = "temporal.schedule.state.remaining-actions"
    package static let scheduleSearchAttributesPrefix = "temporal.schedule.search-attributes."
    package static let scheduleConflictToken = "temporal.schedule.conflict-token"
    package static let scheduleBackfillStartAt = "temporal.schedule.backfill.start-at"
    package static let scheduleBackfillEndAt = "temporal.schedule.backfill.end-at"
    package static let scheduleBackfillOverlapPolicy = "temporal.schedule.backfill.overlap-policy"
    package static let scheduleListQuery = "temporal.schedule.list.query"
    package static let scheduleTriggerImmediately = "temporal.schedule.trigger-immediately"
    package static let schedulePolicyCatchupWindow = "temporal.schedule.policy.catchup-window"
    package static let schedulePolicyOverlap = "temporal.schedule.policy.overlap"
    package static let schedulePolicyPauseOnFailure = "temporal.schedule.policy.pause-on-failure"
    package static let scheduleSpecificationStartAt = "temporal.schedule.specification.start-at"
    package static let scheduleSpecificationEndAt = "temporal.schedule.specification.end-at"
    package static let scheduleSpecificationJitter = "temporal.schedule.specification.jitter"
    package static let scheduleSpecificationTimezoneName = "temporal.schedule.specification.timezone-name"
    package static let scheduleInfoCreatedAt = "temporal.schedule.info.created-at"
    package static let scheduleInfoLastUpdatedAt = "temporal.schedule.info.last-updated-at"
    package static let scheduleInfoNextActionTimes = "temporal.schedule.info.next-action-times"
    package static let scheduleInfoNumActions = "temporal.schedule.info.num-actions"
    package static let scheduleInfoNumActionsBufferDropped = "temporal.schedule.info.num-actions-buffer-dropped"
    package static let scheduleInfoNumActionsInBuffer = "temporal.schedule.info.num-actions-in-buffer"
    package static let scheduleInfoNumActionsMissedCatchupWindow = "temporal.schedule.info.num-actions-missed-catchup-window"
    package static let scheduleInfoNumActionsSkippedOverlap = "temporal.schedule.info.num-actions-skipped-overlap"

    package static let activityTaskToken = "temporal.activity.task-token"
    package static let activityId = "temporal.activity.id"
    package static let activityHeartbeatDetails = "temporal.activity.heartbeat.details"
    package static let activityHeartbeatLastDetails = "temporal.activity.heartbeat.last-details"
    package static let activityFailCause = "temporal.activity.fail.cause"
}
