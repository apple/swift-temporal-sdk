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

package struct LoggingKeys {
    package static let taskToken = TemporalTracingKeys.activityTaskToken
    package static let activityCancellationReason = TemporalTracingKeys.activityCancellationReason
    package static let errorType = "error.type"
    package static let errorMessage = "error.message"
    package static let taskQueue = TemporalTracingKeys.workflowTaskQueue
    package static let workflowID = TemporalTracingKeys.workflowId
    package static let workflowRunID = TemporalTracingKeys.workflowRunId
    package static let workflowType = TemporalTracingKeys.workflowType
    package static let workflowNamespace = TemporalTracingKeys.workflowNamespace
    package static let workflowSignalName = TemporalTracingKeys.workflowSignalName
    package static let workflowQueryID = TemporalTracingKeys.workflowQueryId
    package static let workflowQueryName = TemporalTracingKeys.workflowQueryName
    package static let workflowUpdateID = TemporalTracingKeys.workflowUpdateId
    package static let workflowUpdateName = TemporalTracingKeys.workflowUpdateName
    package static let activityID = TemporalTracingKeys.activityId
    package static let activityName = TemporalTracingKeys.activityName
    package static let activityAttempt = TemporalTracingKeys.activityAttempt
    package static let unfinishedSignalHandlers = TemporalTracingKeys.unfinishedSignalHandlers
    package static let unfinishedUpdateHandlers = TemporalTracingKeys.unfinishedUpdateHandlers
}
