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

import struct Foundation.Date

extension HistoryEvent {
    public enum Attributes: Hashable, Sendable {
        case workflowExecutionStarted(WorkflowExecutionStarted)
        case workflowExecutionCompleted(WorkflowExecutionCompleted)
        case workflowExecutionFailed(WorkflowExecutionFailed)
        case workflowExecutionTimedOut(WorkflowExecutionTimedOut)
        case workflowTaskScheduled(WorkflowTaskScheduled)
        case workflowTaskStarted(WorkflowTaskStarted)
        case workflowTaskCompleted(WorkflowTaskCompleted)
        case workflowTaskTimedOut(WorkflowTaskTimedOut)
        case workflowTaskFailed(WorkflowTaskFailed)
        case activityTaskScheduled(ActivityTaskScheduled)
        case activityTaskStarted(ActivityTaskStarted)
        case activityTaskCompleted(ActivityTaskCompleted)
        case activityTaskFailed(ActivityTaskFailed)
        case activityTaskTimedOut(ActivityTaskTimedOut)
        case timerStarted(TimerStarted)
        case timerFired(TimerFired)
        case activityTaskCancelRequested(ActivityTaskCancelRequested)
        case activityTaskCanceled(ActivityTaskCanceled)
        case timerCanceled(TimerCanceled)
        case markerRecorded(MarkerRecorded)
        case workflowExecutionSignaled(WorkflowExecutionSignaled)
        case workflowExecutionTerminated(WorkflowExecutionTerminated)
        case workflowExecutionCancelRequested(WorkflowExecutionCancelRequested)
        case workflowExecutionCanceled(WorkflowExecutionCanceled)
        case requestCancelExternalWorkflowExecutionInitiated(RequestCancelExternalWorkflowExecutionInitiated)
        case requestCancelExternalWorkflowExecutionFailed(RequestCancelExternalWorkflowExecutionFailed)
        case externalWorkflowExecutionCancelRequested(ExternalWorkflowExecutionCancelRequested)
        case workflowExecutionContinuedAsNew(WorkflowExecutionContinuedAsNew)
        case startChildWorkflowExecutionInitiated(StartChildWorkflowExecutionInitiated)
        case startChildWorkflowExecutionFailed(StartChildWorkflowExecutionFailed)
        case childWorkflowExecutionStarted(ChildWorkflowExecutionStarted)
        case childWorkflowExecutionCompleted(ChildWorkflowExecutionCompleted)
        case childWorkflowExecutionFailed(ChildWorkflowExecutionFailed)
        case childWorkflowExecutionCanceled(ChildWorkflowExecutionCanceled)
        case childWorkflowExecutionTimedOut(ChildWorkflowExecutionTimedOut)
        case childWorkflowExecutionTerminated(ChildWorkflowExecutionTerminated)
        case signalExternalWorkflowExecutionInitiated(SignalExternalWorkflowExecutionInitiated)
        case signalExternalWorkflowExecutionFailed(SignalExternalWorkflowExecutionFailed)
        case externalWorkflowExecutionSignaled(ExternalWorkflowExecutionSignaled)
        case upsertWorkflowSearchAttributes(UpsertWorkflowSearchAttributes)
        case workflowExecutionUpdateAccepted(WorkflowExecutionUpdateAccepted)
        case workflowExecutionUpdateRejected(WorkflowExecutionUpdateRejected)
        case workflowExecutionUpdateCompleted(WorkflowExecutionUpdateCompleted)
        case workflowPropertiesModifiedExternally(WorkflowPropertiesModifiedExternally)
        case activityPropertiesModifiedExternally(ActivityPropertiesModifiedExternally)
        case workflowPropertiesModified(WorkflowPropertiesModified)
        case workflowExecutionUpdateAdmitted(WorkflowExecutionUpdateAdmitted)
        case nexusOperationScheduled(NexusOperationScheduled)
        case nexusOperationStarted(NexusOperationStarted)
        case nexusOperationCompleted(NexusOperationCompleted)
        case nexusOperationFailed(NexusOperationFailed)
        case nexusOperationCanceled(NexusOperationCanceled)
        case nexusOperationTimedOut(NexusOperationTimedOut)
        case nexusOperationCancelRequested(NexusOperationCancelRequested)
        case workflowExecutionOptionsUpdated(WorkflowExecutionOptionsUpdated)
        case nexusOperationCancelRequestCompletedEventAttributes(NexusOperationCancelRequestCompletedEventAttributes)
        case nexusOperationCancelRequestFailedEventAttributes(NexusOperationCancelRequestFailedEventAttributes)
    }
}
