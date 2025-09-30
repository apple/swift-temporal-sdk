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

public enum EventType: Hashable, Sendable {
    case unspecified
    case workflowExecutionStarted
    case workflowExecutionCompleted
    case workflowExecutionFailed
    case workflowExecutionTimedOut
    case workflowTaskScheduled
    case workflowTaskStarted
    case workflowTaskCompleted
    case workflowTaskTimedOut
    case workflowTaskFailed
    case activityTaskScheduled
    case activityTaskStarted
    case activityTaskCompleted
    case activityTaskFailed
    case activityTaskTimedOut
    case activityTaskCancelRequested
    case activityTaskCanceled
    case timerStarted
    case timerFired
    case timerCanceled
    case workflowExecutionCancelRequested
    case workflowExecutionCanceled
    case requestCancelExternalWorkflowExecutionInitiated
    case requestCancelExternalWorkflowExecutionFailed
    case externalWorkflowExecutionCancelRequested
    case markerRecorded
    case workflowExecutionSignaled
    case workflowExecutionTerminated
    case workflowExecutionContinuedAsNew
    case startChildWorkflowExecutionInitiated
    case startChildWorkflowExecutionFailed
    case childWorkflowExecutionStarted
    case childWorkflowExecutionCompleted
    case childWorkflowExecutionFailed
    case childWorkflowExecutionCanceled
    case childWorkflowExecutionTimedOut
    case childWorkflowExecutionTerminated
    case signalExternalWorkflowExecutionInitiated
    case signalExternalWorkflowExecutionFailed
    case externalWorkflowExecutionSignaled
    case upsertWorkflowSearchAttributes
    case workflowExecutionUpdateAdmitted
    case workflowExecutionUpdateAccepted
    case workflowExecutionUpdateRejected
    case workflowExecutionUpdateCompleted
    case workflowPropertiesModifiedExternally
    case activityPropertiesModifiedExternally
    case workflowPropertiesModified
    case nexusOperationScheduled
    case nexusOperationStarted
    case nexusOperationCompleted
    case nexusOperationFailed
    case nexusOperationCanceled
    case nexusOperationTimedOut
    case nexusOperationCancelRequested
    case nexusOperationCancelRequestCompleted
    case nexusOperationCancelRequestFailed
    case workflowExecutionOptionsUpdated
}
