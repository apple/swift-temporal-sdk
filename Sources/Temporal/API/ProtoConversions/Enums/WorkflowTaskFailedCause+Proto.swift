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

extension WorkflowTaskFailedCause {
    init(_ rawValue: Temporal_Api_Enums_V1_WorkflowTaskFailedCause) {
        self =
            switch rawValue {
            case .unspecified: .unspecified
            case .unhandledCommand: .unhandledCommand
            case .badScheduleActivityAttributes: .badScheduleActivityAttributes
            case .badRequestCancelActivityAttributes: .badRequestCancelActivityAttributes
            case .badStartTimerAttributes: .badStartTimerAttributes
            case .badCancelTimerAttributes: .badCancelTimerAttributes
            case .badRecordMarkerAttributes: .badRecordMarkerAttributes
            case .badCompleteWorkflowExecutionAttributes: .badCompleteWorkflowExecutionAttributes
            case .badFailWorkflowExecutionAttributes: .badFailWorkflowExecutionAttributes
            case .badCancelWorkflowExecutionAttributes: .badCancelWorkflowExecutionAttributes
            case .badRequestCancelExternalWorkflowExecutionAttributes: .badRequestCancelExternalWorkflowExecutionAttributes
            case .badContinueAsNewAttributes: .badContinueAsNewAttributes
            case .startTimerDuplicateID: .startTimerDuplicateID
            case .resetStickyTaskQueue: .resetStickyTaskQueue
            case .workflowWorkerUnhandledFailure: .workflowWorkerUnhandledFailure
            case .badSignalWorkflowExecutionAttributes: .badSignalWorkflowExecutionAttributes
            case .badStartChildExecutionAttributes: .badStartChildExecutionAttributes
            case .forceCloseCommand: .forceCloseCommand
            case .failoverCloseCommand: .failoverCloseCommand
            case .badSignalInputSize: .badSignalInputSize
            case .resetWorkflow: .resetWorkflow
            case .badBinary: .badBinary
            case .scheduleActivityDuplicateID: .scheduleActivityDuplicateID
            case .badSearchAttributes: .badSearchAttributes
            case .nonDeterministicError: .nonDeterministicError
            case .badModifyWorkflowPropertiesAttributes: .badModifyWorkflowPropertiesAttributes
            case .pendingChildWorkflowsLimitExceeded: .pendingChildWorkflowsLimitExceeded
            case .pendingActivitiesLimitExceeded: .pendingActivitiesLimitExceeded
            case .pendingSignalsLimitExceeded: .pendingSignalsLimitExceeded
            case .pendingRequestCancelLimitExceeded: .pendingRequestCancelLimitExceeded
            case .badUpdateWorkflowExecutionMessage: .badUpdateWorkflowExecutionMessage
            case .unhandledUpdate: .unhandledUpdate
            case .badScheduleNexusOperationAttributes: .badScheduleNexusOperationAttributes
            case .pendingNexusOperationsLimitExceeded: .pendingNexusOperationsLimitExceeded
            case .badRequestCancelNexusOperationAttributes: .badRequestCancelNexusOperationAttributes
            case .featureDisabled: .featureDisabled
            case .grpcMessageTooLarge: .grpcMessageTooLarge
            case .UNRECOGNIZED(let value):
                fatalError("Unexpected value \(value) for WorkflowTaskFailedCause")
            }
    }
}
