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
    static let taskToken = TemporalTracingKeys.activityTaskToken
    static let activityCancellationReason = TemporalTracingKeys.activityCancellationReason
    static let errorType = "error.type"
    static let errorMessage = "error.message"
    static let taskQueue = TemporalTracingKeys.workflowTaskQueue
    static let workflowID = TemporalTracingKeys.workflowId
    static let workflowRunID = TemporalTracingKeys.workflowRunId
    static let workflowType = TemporalTracingKeys.workflowType
    static let workflowNamespace = TemporalTracingKeys.workflowNamespace
    static let workflowSignalName = TemporalTracingKeys.workflowSignalName
    static let workflowQueryID = TemporalTracingKeys.workflowQueryId
    static let workflowQueryName = TemporalTracingKeys.workflowQueryName
    static let workflowUpdateID = TemporalTracingKeys.workflowUpdateId
    static let workflowUpdateName = TemporalTracingKeys.workflowUpdateName
    static let activityID = TemporalTracingKeys.activityId
    static let activityName = TemporalTracingKeys.activityName
    static let activityAttempt = TemporalTracingKeys.activityAttempt
    static let unfinishedSignalHandlers = TemporalTracingKeys.unfinishedSignalHandlers
    static let unfinishedUpdateHandlers = TemporalTracingKeys.unfinishedUpdateHandlers
}
