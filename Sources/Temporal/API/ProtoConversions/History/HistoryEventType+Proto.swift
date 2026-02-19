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

extension EventType {
    init(_ rawValue: Api.Enums.V1.EventType) {
        self =
            switch rawValue {
            case .unspecified: .unspecified
            case .workflowExecutionStarted: .workflowExecutionStarted
            case .workflowExecutionCompleted: .workflowExecutionCompleted
            case .workflowExecutionFailed: .workflowExecutionFailed
            case .workflowExecutionTimedOut: .workflowExecutionTimedOut
            case .workflowTaskScheduled: .workflowTaskScheduled
            case .workflowTaskStarted: .workflowTaskStarted
            case .workflowTaskCompleted: .workflowTaskCompleted
            case .workflowTaskTimedOut: .workflowTaskTimedOut
            case .workflowTaskFailed: .workflowTaskFailed
            case .activityTaskScheduled: .activityTaskScheduled
            case .activityTaskStarted: .activityTaskStarted
            case .activityTaskCompleted: .activityTaskCompleted
            case .activityTaskFailed: .activityTaskFailed
            case .activityTaskTimedOut: .activityTaskTimedOut
            case .activityTaskCancelRequested: .activityTaskCancelRequested
            case .activityTaskCanceled: .activityTaskCanceled
            case .timerStarted: .timerStarted
            case .timerFired: .timerFired
            case .timerCanceled: .timerCanceled
            case .workflowExecutionCancelRequested: .workflowExecutionCancelRequested
            case .workflowExecutionCanceled: .workflowExecutionCanceled
            case .requestCancelExternalWorkflowExecutionInitiated: .requestCancelExternalWorkflowExecutionInitiated
            case .requestCancelExternalWorkflowExecutionFailed: .requestCancelExternalWorkflowExecutionFailed
            case .externalWorkflowExecutionCancelRequested: .externalWorkflowExecutionCancelRequested
            case .markerRecorded: .markerRecorded
            case .workflowExecutionSignaled: .workflowExecutionSignaled
            case .workflowExecutionTerminated: .workflowExecutionTerminated
            case .workflowExecutionContinuedAsNew: .workflowExecutionContinuedAsNew
            case .startChildWorkflowExecutionInitiated: .startChildWorkflowExecutionInitiated
            case .startChildWorkflowExecutionFailed: .startChildWorkflowExecutionFailed
            case .childWorkflowExecutionStarted: .childWorkflowExecutionStarted
            case .childWorkflowExecutionCompleted: .childWorkflowExecutionCompleted
            case .childWorkflowExecutionFailed: .childWorkflowExecutionFailed
            case .childWorkflowExecutionCanceled: .childWorkflowExecutionCanceled
            case .childWorkflowExecutionTimedOut: .childWorkflowExecutionTimedOut
            case .childWorkflowExecutionTerminated: .childWorkflowExecutionTerminated
            case .signalExternalWorkflowExecutionInitiated: .signalExternalWorkflowExecutionInitiated
            case .signalExternalWorkflowExecutionFailed: .signalExternalWorkflowExecutionFailed
            case .externalWorkflowExecutionSignaled: .externalWorkflowExecutionSignaled
            case .upsertWorkflowSearchAttributes: .upsertWorkflowSearchAttributes
            case .workflowExecutionUpdateAccepted: .workflowExecutionUpdateAccepted
            case .workflowExecutionUpdateRejected: .workflowExecutionUpdateRejected
            case .workflowExecutionUpdateCompleted: .workflowExecutionUpdateCompleted
            case .workflowPropertiesModifiedExternally: .workflowPropertiesModifiedExternally
            case .activityPropertiesModifiedExternally: .activityPropertiesModifiedExternally
            case .workflowPropertiesModified: .workflowPropertiesModified
            case .workflowExecutionUpdateAdmitted: .workflowExecutionUpdateAdmitted
            case .nexusOperationScheduled: .nexusOperationScheduled
            case .nexusOperationStarted: .nexusOperationStarted
            case .nexusOperationCompleted: .nexusOperationCompleted
            case .nexusOperationFailed: .nexusOperationFailed
            case .nexusOperationCanceled: .nexusOperationCanceled
            case .nexusOperationTimedOut: .nexusOperationTimedOut
            case .nexusOperationCancelRequested: .nexusOperationCancelRequested
            case .nexusOperationCancelRequestCompleted: .nexusOperationCancelRequestCompleted
            case .nexusOperationCancelRequestFailed: .nexusOperationCancelRequestFailed
            case .workflowExecutionOptionsUpdated: .workflowExecutionOptionsUpdated
            case .workflowExecutionPaused: .workflowExecutionPaused
            case .workflowExecutionUnpaused: .workflowExecutionUnpaused
            case .UNRECOGNIZED(let value):
                fatalError("Unrecognized rawValue \(value) for EventType.")
            }
    }
}
