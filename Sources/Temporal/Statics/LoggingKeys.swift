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

struct LoggingKeys {
    static let taskToken = "temporal.task.token"
    static let activityCancellationReason = "temporal.activity.cancellation.reason"
    static let errorType = "error.type"
    static let errorMessage = "error.message"
    static let taskQueue = "temporal.taskQueue"
    static let workflowID = TemporalTracingKeys.workflowId
    static let workflowRunID = TemporalTracingKeys.workflowRunId
    static let workflowType = TemporalTracingKeys.workflowType
    static let workflowNamespace = TemporalTracingKeys.workflowNamespace
    static let workflowSignalName = "temporal.workflow.signal.name"
    static let workflowQueryID = "temporal.workflow.query.id"
    static let workflowQueryName = "temporal.workflow.query.name"
    static let workflowUpdateID = "temporal.workflow.update.id"
    static let workflowUpdateName = "temporal.workflow.update.name"
    static let activityID = TemporalTracingKeys.activityID
    static let activityName = "temporal.activity.name"
    static let activityAttempt = "temporal.activity.attempt"
}
