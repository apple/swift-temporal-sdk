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
    static let error = "error"
    static let workflowRunID = "workflow.run.id"
    static let workflowType = "workflow.type"
    static let workflowSignalName = "workflow.signal.name"
    static let workflowQueryID = "workflow.query.id"
    static let workflowQueryName = "workflow.query.name"
    static let workflowUpdateID = "workflow.update.id"
    static let workflowUpdateName = "workflow.update.name"
    static let activityName = "activity.name"
}
