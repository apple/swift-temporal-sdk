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

extension HistoryEvent.Attributes {
    init(_ rawValue: Temporal_Api_History_V1_HistoryEvent.OneOf_Attributes) throws {
        self =
            switch rawValue {
            case .workflowExecutionStartedEventAttributes(let attributes):
                try .workflowExecutionStarted(.init(attributes))
            case .workflowExecutionCompletedEventAttributes(let attributes):
                .workflowExecutionCompleted(.init(attributes))
            case .workflowExecutionFailedEventAttributes(let attributes):
                .workflowExecutionFailed(.init(attributes))
            case .workflowExecutionTimedOutEventAttributes(let attributes):
                .workflowExecutionTimedOut(.init(attributes))
            case .workflowTaskScheduledEventAttributes(let attributes):
                .workflowTaskScheduled(.init(attributes))
            case .workflowTaskStartedEventAttributes(let attributes):
                .workflowTaskStarted(.init(attributes))
            case .workflowTaskCompletedEventAttributes(let attributes):
                .workflowTaskCompleted(.init(attributes))
            case .workflowTaskTimedOutEventAttributes(let attributes):
                .workflowTaskTimedOut(.init(attributes))
            case .workflowTaskFailedEventAttributes(let attributes):
                .workflowTaskFailed(.init(attributes))
            case .activityTaskScheduledEventAttributes(let attributes):
                .activityTaskScheduled(.init(attributes))
            case .activityTaskStartedEventAttributes(let attributes):
                .activityTaskStarted(.init(attributes))
            case .activityTaskCompletedEventAttributes(let attributes):
                .activityTaskCompleted(.init(attributes))
            case .activityTaskFailedEventAttributes(let attributes):
                .activityTaskFailed(.init(attributes))
            case .activityTaskTimedOutEventAttributes(let attributes):
                .activityTaskTimedOut(.init(attributes))
            case .timerStartedEventAttributes(let attributes):
                .timerStarted(.init(attributes))
            case .timerFiredEventAttributes(let attributes):
                .timerFired(.init(attributes))
            case .activityTaskCancelRequestedEventAttributes(let attributes):
                .activityTaskCancelRequested(.init(attributes))
            case .activityTaskCanceledEventAttributes(let attributes):
                .activityTaskCanceled(.init(attributes))
            case .timerCanceledEventAttributes(let attributes):
                .timerCanceled(.init(attributes))
            case .markerRecordedEventAttributes(let attributes):
                .markerRecorded(.init(attributes))
            case .workflowExecutionSignaledEventAttributes(let attributes):
                .workflowExecutionSignaled(.init(attributes))
            case .workflowExecutionTerminatedEventAttributes(let attributes):
                .workflowExecutionTerminated(.init(attributes))
            case .workflowExecutionCancelRequestedEventAttributes(let attributes):
                .workflowExecutionCancelRequested(.init(attributes))
            case .workflowExecutionCanceledEventAttributes(let attributes):
                .workflowExecutionCanceled(.init(attributes))
            case .requestCancelExternalWorkflowExecutionInitiatedEventAttributes(let attributes):
                .requestCancelExternalWorkflowExecutionInitiated(.init(attributes))
            case .requestCancelExternalWorkflowExecutionFailedEventAttributes(let attributes):
                .requestCancelExternalWorkflowExecutionFailed(.init(attributes))
            case .externalWorkflowExecutionCancelRequestedEventAttributes(let attributes):
                .externalWorkflowExecutionCancelRequested(.init(attributes))
            case .workflowExecutionContinuedAsNewEventAttributes(let attributes):
                try .workflowExecutionContinuedAsNew(.init(attributes))
            case .startChildWorkflowExecutionInitiatedEventAttributes(let attributes):
                try .startChildWorkflowExecutionInitiated(.init(attributes))
            case .startChildWorkflowExecutionFailedEventAttributes(let attributes):
                .startChildWorkflowExecutionFailed(.init(attributes))
            case .childWorkflowExecutionStartedEventAttributes(let attributes):
                .childWorkflowExecutionStarted(.init(attributes))
            case .childWorkflowExecutionCompletedEventAttributes(let attributes):
                .childWorkflowExecutionCompleted(.init(attributes))
            case .childWorkflowExecutionFailedEventAttributes(let attributes):
                .childWorkflowExecutionFailed(.init(attributes))
            case .childWorkflowExecutionCanceledEventAttributes(let attributes):
                .childWorkflowExecutionCanceled(.init(attributes))
            case .childWorkflowExecutionTimedOutEventAttributes(let attributes):
                .childWorkflowExecutionTimedOut(.init(attributes))
            case .childWorkflowExecutionTerminatedEventAttributes(let attributes):
                .childWorkflowExecutionTerminated(.init(attributes))
            case .signalExternalWorkflowExecutionInitiatedEventAttributes(let attributes):
                .signalExternalWorkflowExecutionInitiated(.init(attributes))
            case .signalExternalWorkflowExecutionFailedEventAttributes(let attributes):
                .signalExternalWorkflowExecutionFailed(.init(attributes))
            case .externalWorkflowExecutionSignaledEventAttributes(let attributes):
                .externalWorkflowExecutionSignaled(.init(attributes))
            case .upsertWorkflowSearchAttributesEventAttributes(let attributes):
                try .upsertWorkflowSearchAttributes(.init(attributes))
            case .workflowExecutionUpdateAcceptedEventAttributes(let attributes):
                .workflowExecutionUpdateAccepted(.init(attributes))
            case .workflowExecutionUpdateRejectedEventAttributes(let attributes):
                .workflowExecutionUpdateRejected(.init(attributes))
            case .workflowExecutionUpdateCompletedEventAttributes(let attributes):
                .workflowExecutionUpdateCompleted(.init(attributes))
            case .workflowPropertiesModifiedExternallyEventAttributes(let attributes):
                .workflowPropertiesModifiedExternally(.init(attributes))
            case .activityPropertiesModifiedExternallyEventAttributes(let attributes):
                .activityPropertiesModifiedExternally(.init(attributes))
            case .workflowPropertiesModifiedEventAttributes(let attributes):
                .workflowPropertiesModified(.init(attributes))
            case .workflowExecutionUpdateAdmittedEventAttributes(let attributes):
                .workflowExecutionUpdateAdmitted(.init(attributes))
            case .nexusOperationScheduledEventAttributes(let attributes):
                .nexusOperationScheduled(.init(attributes))
            case .nexusOperationStartedEventAttributes(let attributes):
                .nexusOperationStarted(.init(attributes))
            case .nexusOperationCompletedEventAttributes(let attributes):
                .nexusOperationCompleted(.init(attributes))
            case .nexusOperationFailedEventAttributes(let attributes):
                .nexusOperationFailed(.init(attributes))
            case .nexusOperationCanceledEventAttributes(let attributes):
                .nexusOperationCanceled(.init(attributes))
            case .nexusOperationTimedOutEventAttributes(let attributes):
                .nexusOperationTimedOut(.init(attributes))
            case .nexusOperationCancelRequestedEventAttributes(let attributes):
                .nexusOperationCancelRequested(.init(attributes))
            case .workflowExecutionOptionsUpdatedEventAttributes(let attributes):
                .workflowExecutionOptionsUpdated(.init(attributes))
            case .nexusOperationCancelRequestCompletedEventAttributes(let attributes):
                .nexusOperationCancelRequestCompletedEventAttributes(.init(attributes))
            case .nexusOperationCancelRequestFailedEventAttributes(let attributes):
                .nexusOperationCancelRequestFailedEventAttributes(.init(attributes))
            }
    }
}

extension HistoryEvent.Attributes.WorkflowExecutionStarted {
    init(_ rawValue: Temporal_Api_History_V1_WorkflowExecutionStartedEventAttributes) throws {
        self = .init(
            workflowType: rawValue.workflowType.name,
            parentWorkflowNamespace: rawValue.parentWorkflowNamespace.nilIfEmpty,
            parentWorkflowNamespaceID: rawValue.parentWorkflowNamespaceID.nilIfEmpty,
            parentWorkflowExecution: rawValue.hasParentWorkflowExecution ? .init(rawValue.parentWorkflowExecution) : nil,
            parentInitiatedEventID: rawValue.parentInitiatedEventID > 0 ? Int(rawValue.parentInitiatedEventID) : nil,
            taskQueue: .init(rawValue.taskQueue),
            input: rawValue.input.payloads.map { .init(temporalAPIPayload: $0) },
            workflowExecutionTimeout: rawValue.hasWorkflowExecutionTimeout ? .init(rawValue.workflowExecutionTimeout) : nil,
            workflowRunTimeout: rawValue.hasWorkflowRunTimeout ? .init(rawValue.workflowRunTimeout) : nil,
            workflowTaskTimeout: rawValue.hasWorkflowTaskTimeout ? .init(rawValue.workflowTaskTimeout) : nil,
            continuedExecutionRunID: rawValue.continuedExecutionRunID.nilIfEmpty,
            initiator: .init(rawValue.initiator),
            continuedFailure: rawValue.hasContinuedFailure ? .init(temporalAPIFailure: rawValue.continuedFailure) : nil,
            lastCompletionResult: rawValue.lastCompletionResult.payloads.map { .init(temporalAPIPayload: $0) },
            originalExecutionRunID: rawValue.originalExecutionRunID,
            identity: rawValue.identity.nilIfEmpty,
            firstExecutionRunID: rawValue.firstExecutionRunID,
            retryPolicy: rawValue.hasRetryPolicy ? .init(retryPolicy: rawValue.retryPolicy) : nil,
            attempt: Int(rawValue.attempt),
            workflowExecutionExpirationTime: rawValue.hasWorkflowExecutionExpirationTime ? rawValue.workflowExecutionExpirationTime.date : nil,
            cronSchedule: rawValue.cronSchedule.nilIfEmpty,
            firstWorkflowTaskBackoff: rawValue.hasFirstWorkflowTaskBackoff ? .init(rawValue.firstWorkflowTaskBackoff) : nil,
            memo: rawValue.memo.fields.mapValues { .init(temporalAPIPayload: $0) },
            searchAttributes: try .init(rawValue.searchAttributes),
            prevAutoResetPoints: rawValue.prevAutoResetPoints.points.map { .init($0) },
            headers: rawValue.header.fields.mapValues { .init(temporalAPIPayload: $0) },
            parentInitiatedEventVersion: rawValue.parentInitiatedEventVersion > 0 ? Int(rawValue.parentInitiatedEventVersion) : nil,
            workflowID: rawValue.workflowID,
            sourceVersionStamp: rawValue.hasSourceVersionStamp ? .init(rawValue.sourceVersionStamp) : nil,
            completionCallbacks: rawValue.completionCallbacks.map { .init($0) },
            rootWorkflowExecution: rawValue.hasRootWorkflowExecution ? .init(rawValue.rootWorkflowExecution) : nil,
            inheritedBuildID: rawValue.inheritedBuildID.nilIfEmpty,
            versioningOverride: rawValue.hasVersioningOverride ? .init(rawValue.versioningOverride) : nil,
            parentPinnedWorkerDeploymentVersion: rawValue.parentPinnedWorkerDeploymentVersion.nilIfEmpty,
            priority: rawValue.hasPriority ? .init(rawValue.priority) : nil
        )
    }
}

extension HistoryEvent.Attributes.WorkflowExecutionCompleted {
    init(_ rawValue: Temporal_Api_History_V1_WorkflowExecutionCompletedEventAttributes) {
        self = .init(
            result: rawValue.result.payloads.map { .init(temporalAPIPayload: $0) },
            workflowTaskCompletedEventID: Int(rawValue.workflowTaskCompletedEventID),
            newExecutionRunID: rawValue.newExecutionRunID.nilIfEmpty
        )
    }
}

extension HistoryEvent.Attributes.WorkflowExecutionFailed {
    init(_ rawValue: Temporal_Api_History_V1_WorkflowExecutionFailedEventAttributes) {
        self = .init(
            failure: .init(temporalAPIFailure: rawValue.failure),
            retryState: .init(retryState: rawValue.retryState),
            workflowTaskCompletedEventID: Int(rawValue.workflowTaskCompletedEventID),
            newExecutionRunID: rawValue.newExecutionRunID.nilIfEmpty
        )
    }
}

extension HistoryEvent.Attributes.WorkflowExecutionTimedOut {
    init(_ rawValue: Temporal_Api_History_V1_WorkflowExecutionTimedOutEventAttributes) {
        self = .init(
            retryState: .init(retryState: rawValue.retryState),
            newExecutionRunID: rawValue.newExecutionRunID.nilIfEmpty
        )
    }
}

extension HistoryEvent.Attributes.WorkflowTaskScheduled {
    init(_ rawValue: Temporal_Api_History_V1_WorkflowTaskScheduledEventAttributes) {
        self = .init(
            taskQueue: .init(rawValue.taskQueue),
            startToCloseTimeout: rawValue.hasStartToCloseTimeout ? .init(rawValue.startToCloseTimeout) : nil,
            attempt: Int(rawValue.attempt)
        )
    }
}

extension HistoryEvent.Attributes.WorkflowTaskStarted {
    init(_ rawValue: Temporal_Api_History_V1_WorkflowTaskStartedEventAttributes) {
        self = .init(
            scheduledEventID: Int(rawValue.scheduledEventID),
            identity: rawValue.identity.nilIfEmpty,
            requestID: rawValue.requestID,
            suggestContinueAsNew: rawValue.suggestContinueAsNew,
            historySizeBytes: Int(rawValue.historySizeBytes),
            workerVersion: rawValue.hasWorkerVersion ? .init(rawValue.workerVersion) : nil,
            buildIDRedirectCounter: Int(rawValue.buildIDRedirectCounter)
        )
    }
}

extension HistoryEvent.Attributes.WorkflowTaskCompleted {
    init(_ rawValue: Temporal_Api_History_V1_WorkflowTaskCompletedEventAttributes) {
        self = .init(
            scheduledEventID: Int(rawValue.scheduledEventID),
            startedEventID: Int(rawValue.startedEventID),
            identity: rawValue.identity.nilIfEmpty,
            binaryChecksum: rawValue.binaryChecksum.nilIfEmpty,
            workerVersion: rawValue.hasWorkerVersion ? .init(rawValue.workerVersion) : nil,
            sdkMetadata: rawValue.hasSdkMetadata ? .init(rawValue.sdkMetadata) : nil,
            meteringMetadata: .init(rawValue.meteringMetadata),
            deployment: rawValue.hasDeployment ? .init(rawValue.deployment) : nil,
            versioningBehavior: .init(rawValue.versioningBehavior),
            workerDeploymentVersion: rawValue.workerDeploymentVersion.nilIfEmpty,
            workerDeploymentName: rawValue.workerDeploymentName.nilIfEmpty
        )
    }
}

extension HistoryEvent.Attributes.WorkflowTaskTimedOut {
    init(_ rawValue: Temporal_Api_History_V1_WorkflowTaskTimedOutEventAttributes) {
        self = .init(
            scheduledEventID: Int(rawValue.scheduledEventID),
            startedEventID: Int(rawValue.startedEventID),
            timeoutType: .init(rawValue.timeoutType)
        )
    }
}

extension HistoryEvent.Attributes.WorkflowTaskFailed {
    init(_ rawValue: Temporal_Api_History_V1_WorkflowTaskFailedEventAttributes) {
        self = .init(
            scheduledEventID: Int(rawValue.scheduledEventID),
            startedEventID: Int(rawValue.startedEventID),
            cause: .init(rawValue.cause),
            failure: .init(temporalAPIFailure: rawValue.failure),
            identity: rawValue.identity.nilIfEmpty,
            baseRunID: rawValue.baseRunID.nilIfEmpty,
            newRunID: rawValue.newRunID.nilIfEmpty,
            forkEventVersion: Int(rawValue.forkEventVersion),
            binaryChecksum: rawValue.binaryChecksum.nilIfEmpty,
            workerVersion: rawValue.hasWorkerVersion ? .init(rawValue.workerVersion) : nil
        )
    }
}

extension HistoryEvent.Attributes.ActivityTaskScheduled {
    init(_ rawValue: Temporal_Api_History_V1_ActivityTaskScheduledEventAttributes) {
        self = .init(
            activityID: rawValue.activityID,
            activityType: rawValue.activityType.name,
            taskQueue: .init(rawValue.taskQueue),
            headers: rawValue.header.fields.mapValues { .init(temporalAPIPayload: $0) },
            input: rawValue.input.payloads.map { .init(temporalAPIPayload: $0) },
            scheduleToCloseTimeout: rawValue.hasScheduleToCloseTimeout ? .init(rawValue.scheduleToCloseTimeout) : nil,
            scheduleToStartTimeout: rawValue.hasScheduleToStartTimeout ? .init(rawValue.scheduleToStartTimeout) : nil,
            startToCloseTimeout: rawValue.hasStartToCloseTimeout ? .init(rawValue.startToCloseTimeout) : nil,
            heartbeatTimeout: rawValue.hasHeartbeatTimeout ? .init(rawValue.heartbeatTimeout) : nil,
            workflowTaskCompletedEventID: Int(rawValue.workflowTaskCompletedEventID),
            retryPolicy: rawValue.hasRetryPolicy ? .init(retryPolicy: rawValue.retryPolicy) : nil,
            useWorkflowBuildID: rawValue.useWorkflowBuildID,
            priority: rawValue.hasPriority ? .init(rawValue.priority) : nil
        )
    }
}

extension HistoryEvent.Attributes.ActivityTaskStarted {
    init(_ rawValue: Temporal_Api_History_V1_ActivityTaskStartedEventAttributes) {
        self = .init(
            scheduledEventID: Int(rawValue.scheduledEventID),
            identity: rawValue.identity.nilIfEmpty,
            requestID: rawValue.requestID,
            attempt: Int(rawValue.attempt),
            lastFailure: rawValue.hasLastFailure ? .init(temporalAPIFailure: rawValue.lastFailure) : nil,
            workerVersion: rawValue.hasWorkerVersion ? .init(rawValue.workerVersion) : nil,
            buildIDRedirectCounter: Int(rawValue.buildIDRedirectCounter)
        )
    }
}

extension HistoryEvent.Attributes.ActivityTaskCompleted {
    init(_ rawValue: Temporal_Api_History_V1_ActivityTaskCompletedEventAttributes) {
        self = .init(
            result: rawValue.result.payloads.map { .init(temporalAPIPayload: $0) },
            scheduledEventID: Int(rawValue.scheduledEventID),
            startedEventID: Int(rawValue.startedEventID),
            identity: rawValue.identity.nilIfEmpty,
            workerVersion: rawValue.hasWorkerVersion ? .init(rawValue.workerVersion) : nil
        )
    }
}

extension HistoryEvent.Attributes.ActivityTaskFailed {
    init(_ rawValue: Temporal_Api_History_V1_ActivityTaskFailedEventAttributes) {
        self = .init(
            failure: .init(temporalAPIFailure: rawValue.failure),
            scheduledEventID: Int(rawValue.scheduledEventID),
            startedEventID: Int(rawValue.startedEventID),
            identity: rawValue.identity.nilIfEmpty,
            retryState: .init(retryState: rawValue.retryState),
            workerVersion: rawValue.hasWorkerVersion ? .init(rawValue.workerVersion) : nil
        )
    }
}

extension HistoryEvent.Attributes.ActivityTaskTimedOut {
    init(_ rawValue: Temporal_Api_History_V1_ActivityTaskTimedOutEventAttributes) {
        self = .init(
            failure: rawValue.hasFailure ? .init(temporalAPIFailure: rawValue.failure) : nil,
            scheduledEventID: Int(rawValue.scheduledEventID),
            startedEventID: Int(rawValue.startedEventID),
            retryState: .init(retryState: rawValue.retryState)
        )
    }
}

extension HistoryEvent.Attributes.TimerStarted {
    init(_ rawValue: Temporal_Api_History_V1_TimerStartedEventAttributes) {
        self = .init(
            timerID: rawValue.timerID,
            startToFireTimeout: .init(rawValue.startToFireTimeout),
            workflowTaskCompletedEventID: Int(rawValue.workflowTaskCompletedEventID)
        )
    }
}

extension HistoryEvent.Attributes.TimerFired {
    init(_ rawValue: Temporal_Api_History_V1_TimerFiredEventAttributes) {
        self = .init(
            timerID: rawValue.timerID,
            startedEventID: Int(rawValue.startedEventID)
        )
    }
}

extension HistoryEvent.Attributes.ActivityTaskCancelRequested {
    init(_ rawValue: Temporal_Api_History_V1_ActivityTaskCancelRequestedEventAttributes) {
        self = .init(
            scheduledEventID: Int(rawValue.scheduledEventID),
            workflowTaskCompletedEventID: Int(rawValue.workflowTaskCompletedEventID)
        )
    }
}

extension HistoryEvent.Attributes.ActivityTaskCanceled {
    init(_ rawValue: Temporal_Api_History_V1_ActivityTaskCanceledEventAttributes) {
        self = .init(
            details: rawValue.details.payloads.map { .init(temporalAPIPayload: $0) },
            latestCancelRequestedEventID: Int(rawValue.latestCancelRequestedEventID),
            scheduledEventID: Int(rawValue.scheduledEventID),
            startedEventID: Int(rawValue.startedEventID),
            identity: rawValue.identity.nilIfEmpty,
            workerVersion: rawValue.hasWorkerVersion ? .init(rawValue.workerVersion) : nil
        )
    }
}

extension HistoryEvent.Attributes.TimerCanceled {
    init(_ rawValue: Temporal_Api_History_V1_TimerCanceledEventAttributes) {
        self = .init(
            timerID: rawValue.timerID,
            startedEventID: Int(rawValue.startedEventID),
            workflowTaskCompletedEventID: Int(rawValue.workflowTaskCompletedEventID),
            identity: rawValue.identity.nilIfEmpty
        )
    }
}

extension HistoryEvent.Attributes.MarkerRecorded {
    init(_ rawValue: Temporal_Api_History_V1_MarkerRecordedEventAttributes) {
        self = .init(
            markerName: rawValue.markerName,
            details: rawValue.details.mapValues { $0.payloads.map { .init(temporalAPIPayload: $0) } },
            workflowTaskCompletedEventID: Int(rawValue.workflowTaskCompletedEventID),
            headers: rawValue.header.fields.mapValues { .init(temporalAPIPayload: $0) },
            failure: rawValue.hasFailure ? .init(temporalAPIFailure: rawValue.failure) : nil
        )
    }
}

extension HistoryEvent.Attributes.WorkflowExecutionSignaled {
    init(_ rawValue: Temporal_Api_History_V1_WorkflowExecutionSignaledEventAttributes) {
        self = .init(
            signalName: rawValue.signalName,
            input: rawValue.input.payloads.map { .init(temporalAPIPayload: $0) },
            identity: rawValue.identity.nilIfEmpty,
            headers: rawValue.header.fields.mapValues { .init(temporalAPIPayload: $0) },
            skipGenerateWorkflowTask: rawValue.skipGenerateWorkflowTask,
            externalWorkflowExecution: .init(rawValue.externalWorkflowExecution)
        )
    }
}

extension HistoryEvent.Attributes.WorkflowExecutionTerminated {
    init(_ rawValue: Temporal_Api_History_V1_WorkflowExecutionTerminatedEventAttributes) {
        self = .init(
            reason: rawValue.reason.nilIfEmpty,
            details: rawValue.details.payloads.map { .init(temporalAPIPayload: $0) },
            identity: rawValue.identity.nilIfEmpty
        )
    }
}

extension HistoryEvent.Attributes.WorkflowExecutionCancelRequested {
    init(_ rawValue: Temporal_Api_History_V1_WorkflowExecutionCancelRequestedEventAttributes) {
        self = .init(
            cause: rawValue.cause.nilIfEmpty,
            externalInitiatedEventID: Int(rawValue.externalInitiatedEventID),
            externalWorkflowExecution: .init(rawValue.externalWorkflowExecution),
            identity: rawValue.identity.nilIfEmpty
        )
    }
}

extension HistoryEvent.Attributes.WorkflowExecutionCanceled {
    init(_ rawValue: Temporal_Api_History_V1_WorkflowExecutionCanceledEventAttributes) {
        self = .init(
            workflowTaskCompletedEventID: Int(rawValue.workflowTaskCompletedEventID),
            details: rawValue.details.payloads.map { .init(temporalAPIPayload: $0) }
        )
    }
}

extension HistoryEvent.Attributes.RequestCancelExternalWorkflowExecutionInitiated {
    init(_ rawValue: Temporal_Api_History_V1_RequestCancelExternalWorkflowExecutionInitiatedEventAttributes) {
        self = .init(
            workflowTaskCompletedEventID: Int(rawValue.workflowTaskCompletedEventID),
            namespace: rawValue.namespace,
            namespaceID: rawValue.namespaceID,
            workflowExecution: .init(rawValue.workflowExecution),
            control: rawValue.control.nilIfEmpty,
            childWorkflowOnly: rawValue.childWorkflowOnly,
            reason: rawValue.reason.nilIfEmpty
        )
    }
}

extension HistoryEvent.Attributes.RequestCancelExternalWorkflowExecutionFailed {
    init(_ rawValue: Temporal_Api_History_V1_RequestCancelExternalWorkflowExecutionFailedEventAttributes) {
        self = .init(
            cause: .init(rawValue.cause),
            workflowTaskCompletedEventID: Int(rawValue.workflowTaskCompletedEventID),
            namespace: rawValue.namespace,
            namespaceID: rawValue.namespaceID,
            workflowExecution: .init(rawValue.workflowExecution),
            initiatedEventID: Int(rawValue.initiatedEventID),
            control: rawValue.control.nilIfEmpty
        )
    }
}

extension HistoryEvent.Attributes.ExternalWorkflowExecutionCancelRequested {
    init(_ rawValue: Temporal_Api_History_V1_ExternalWorkflowExecutionCancelRequestedEventAttributes) {
        self = .init(
            initiatedEventID: Int(rawValue.initiatedEventID),
            namespace: rawValue.namespace,
            namespaceID: rawValue.namespaceID,
            workflowExecution: .init(rawValue.workflowExecution)
        )
    }
}

extension HistoryEvent.Attributes.WorkflowExecutionContinuedAsNew {
    init(_ rawValue: Temporal_Api_History_V1_WorkflowExecutionContinuedAsNewEventAttributes) throws {
        self = .init(
            newExecutionRunID: rawValue.newExecutionRunID,
            workflowType: rawValue.workflowType.name,
            taskQueue: .init(rawValue.taskQueue),
            input: rawValue.input.payloads.map { .init(temporalAPIPayload: $0) },
            workflowTaskCompletedEventID: Int(rawValue.workflowTaskCompletedEventID),
            initiator: .init(rawValue.initiator),
            failure: rawValue.hasFailure ? .init(temporalAPIFailure: rawValue.failure) : nil,
            lastCompletionResult: rawValue.lastCompletionResult.payloads.map { .init(temporalAPIPayload: $0) },
            headers: rawValue.header.fields.mapValues { .init(temporalAPIPayload: $0) },
            memo: rawValue.memo.fields.mapValues { .init(temporalAPIPayload: $0) },
            searchAttributes: try .init(rawValue.searchAttributes),
            inheritBuildID: rawValue.inheritBuildID
        )
    }
}

extension HistoryEvent.Attributes.StartChildWorkflowExecutionInitiated {
    init(_ rawValue: Temporal_Api_History_V1_StartChildWorkflowExecutionInitiatedEventAttributes) throws {
        self = .init(
            namespace: rawValue.namespace,
            namespaceID: rawValue.namespaceID,
            workflowID: rawValue.workflowID,
            workflowType: rawValue.workflowType.name,
            taskQueue: .init(rawValue.taskQueue),
            input: rawValue.input.payloads.map { .init(temporalAPIPayload: $0) },
            workflowExecutionTimeout: rawValue.hasWorkflowExecutionTimeout ? .init(rawValue.workflowExecutionTimeout) : nil,
            workflowRunTimeout: rawValue.hasWorkflowRunTimeout ? .init(rawValue.workflowRunTimeout) : nil,
            workflowTaskTimeout: rawValue.hasWorkflowTaskTimeout ? .init(rawValue.workflowTaskTimeout) : nil,
            parentClosePolicy: .init(rawValue.parentClosePolicy),
            control: rawValue.control.nilIfEmpty,
            workflowTaskCompletedEventID: Int(rawValue.workflowTaskCompletedEventID),
            workflowIDReusePolicy: .init(rawValue.workflowIDReusePolicy),
            retryPolicy: rawValue.hasRetryPolicy ? .init(retryPolicy: rawValue.retryPolicy) : nil,
            cronSchedule: rawValue.cronSchedule.nilIfEmpty,
            headers: rawValue.header.fields.mapValues { .init(temporalAPIPayload: $0) },
            memo: rawValue.memo.fields.mapValues { .init(temporalAPIPayload: $0) },
            searchAttributes: try .init(rawValue.searchAttributes),
            inheritBuildID: rawValue.inheritBuildID,
            priority: rawValue.hasPriority ? .init(rawValue.priority) : nil
        )
    }
}

extension HistoryEvent.Attributes.StartChildWorkflowExecutionFailed {
    init(_ rawValue: Temporal_Api_History_V1_StartChildWorkflowExecutionFailedEventAttributes) {
        self = .init(
            namespace: rawValue.namespace,
            namespaceID: rawValue.namespaceID,
            workflowID: rawValue.workflowID,
            workflowType: rawValue.workflowType.name,
            cause: .init(rawValue.cause),
            control: rawValue.control.nilIfEmpty,
            initiatedEventID: Int(rawValue.initiatedEventID),
            workflowTaskCompletedEventID: Int(rawValue.workflowTaskCompletedEventID)
        )
    }
}

extension HistoryEvent.Attributes.ChildWorkflowExecutionStarted {
    init(_ rawValue: Temporal_Api_History_V1_ChildWorkflowExecutionStartedEventAttributes) {
        self = .init(
            namespace: rawValue.namespace,
            namespaceID: rawValue.namespaceID,
            initiatedEventID: Int(rawValue.initiatedEventID),
            workflowExecution: .init(rawValue.workflowExecution),
            workflowType: rawValue.workflowType.name,
            headers: rawValue.header.fields.mapValues { .init(temporalAPIPayload: $0) }
        )
    }
}

extension HistoryEvent.Attributes.ChildWorkflowExecutionCompleted {
    init(_ rawValue: Temporal_Api_History_V1_ChildWorkflowExecutionCompletedEventAttributes) {
        self = .init(
            result: rawValue.result.payloads.map { .init(temporalAPIPayload: $0) },
            namespace: rawValue.namespace,
            namespaceID: rawValue.namespaceID,
            workflowExecution: .init(rawValue.workflowExecution),
            workflowType: rawValue.workflowType.name,
            initiatedEventID: Int(rawValue.initiatedEventID),
            startedEventID: Int(rawValue.startedEventID)
        )
    }
}

extension HistoryEvent.Attributes.ChildWorkflowExecutionFailed {
    init(_ rawValue: Temporal_Api_History_V1_ChildWorkflowExecutionFailedEventAttributes) {
        self = .init(
            failure: .init(temporalAPIFailure: rawValue.failure),
            namespace: rawValue.namespace,
            namespaceID: rawValue.namespaceID,
            workflowExecution: .init(rawValue.workflowExecution),
            workflowType: rawValue.workflowType.name,
            initiatedEventID: Int(rawValue.initiatedEventID),
            startedEventID: Int(rawValue.startedEventID),
            retryState: .init(retryState: rawValue.retryState)
        )
    }
}

extension HistoryEvent.Attributes.ChildWorkflowExecutionCanceled {
    init(_ rawValue: Temporal_Api_History_V1_ChildWorkflowExecutionCanceledEventAttributes) {
        self = .init(
            details: rawValue.details.payloads.map { .init(temporalAPIPayload: $0) },
            namespace: rawValue.namespace,
            namespaceID: rawValue.namespaceID,
            workflowExecution: .init(rawValue.workflowExecution),
            workflowType: rawValue.workflowType.name,
            initiatedEventID: Int(rawValue.initiatedEventID),
            startedEventID: Int(rawValue.startedEventID)
        )
    }
}

extension HistoryEvent.Attributes.ChildWorkflowExecutionTimedOut {
    init(_ rawValue: Temporal_Api_History_V1_ChildWorkflowExecutionTimedOutEventAttributes) {
        self = .init(
            namespace: rawValue.namespace,
            namespaceID: rawValue.namespaceID,
            workflowExecution: .init(rawValue.workflowExecution),
            workflowType: rawValue.workflowType.name,
            initiatedEventID: Int(rawValue.initiatedEventID),
            startedEventID: Int(rawValue.startedEventID),
            retryState: .init(retryState: rawValue.retryState)
        )
    }
}

extension HistoryEvent.Attributes.ChildWorkflowExecutionTerminated {
    init(_ rawValue: Temporal_Api_History_V1_ChildWorkflowExecutionTerminatedEventAttributes) {
        self = .init(
            namespace: rawValue.namespace,
            namespaceID: rawValue.namespaceID,
            workflowExecution: .init(rawValue.workflowExecution),
            workflowType: rawValue.workflowType.name,
            initiatedEventID: Int(rawValue.initiatedEventID),
            startedEventID: Int(rawValue.startedEventID)
        )
    }
}

extension HistoryEvent.Attributes.SignalExternalWorkflowExecutionInitiated {
    init(_ rawValue: Temporal_Api_History_V1_SignalExternalWorkflowExecutionInitiatedEventAttributes) {
        self = .init(
            workflowTaskCompletedEventID: Int(rawValue.workflowTaskCompletedEventID),
            namespace: rawValue.namespace,
            namespaceID: rawValue.namespaceID,
            workflowExecution: .init(rawValue.workflowExecution),
            signalName: rawValue.signalName,
            input: rawValue.input.payloads.map { .init(temporalAPIPayload: $0) },
            control: rawValue.control.nilIfEmpty,
            childWorkflowOnly: rawValue.childWorkflowOnly,
            headers: rawValue.header.fields.mapValues { .init(temporalAPIPayload: $0) },
        )
    }
}

extension HistoryEvent.Attributes.SignalExternalWorkflowExecutionFailed {
    init(_ rawValue: Temporal_Api_History_V1_SignalExternalWorkflowExecutionFailedEventAttributes) {
        self = .init(
            cause: .init(rawValue.cause),
            workflowTaskCompletedEventID: Int(rawValue.workflowTaskCompletedEventID),
            namespace: rawValue.namespace,
            namespaceID: rawValue.namespaceID,
            workflowExecution: .init(rawValue.workflowExecution),
            initiatedEventID: Int(rawValue.initiatedEventID),
            control: rawValue.control.nilIfEmpty
        )
    }
}

extension HistoryEvent.Attributes.ExternalWorkflowExecutionSignaled {
    init(_ rawValue: Temporal_Api_History_V1_ExternalWorkflowExecutionSignaledEventAttributes) {
        self = .init(
            initiatedEventID: Int(rawValue.initiatedEventID),
            namespace: rawValue.namespace,
            namespaceID: rawValue.namespaceID,
            workflowExecution: .init(rawValue.workflowExecution),
            control: rawValue.control.nilIfEmpty
        )
    }
}

extension HistoryEvent.Attributes.UpsertWorkflowSearchAttributes {
    init(_ rawValue: Temporal_Api_History_V1_UpsertWorkflowSearchAttributesEventAttributes) throws {
        self = .init(
            workflowTaskCompletedEventID: Int(rawValue.workflowTaskCompletedEventID),
            searchAttributes: try .init(rawValue.searchAttributes)
        )
    }
}

extension HistoryEvent.Attributes.WorkflowExecutionUpdateAccepted {
    init(_ rawValue: Temporal_Api_History_V1_WorkflowExecutionUpdateAcceptedEventAttributes) {
        self = .init(
            protocolInstanceID: rawValue.protocolInstanceID,
            acceptedRequestMessageID: rawValue.acceptedRequestMessageID,
            acceptedRequestSequencingEventID: Int(rawValue.acceptedRequestSequencingEventID),
            acceptedRequest: .init(rawValue.acceptedRequest)
        )
    }
}

extension HistoryEvent.Attributes.WorkflowExecutionUpdateRejected {
    init(_ rawValue: Temporal_Api_History_V1_WorkflowExecutionUpdateRejectedEventAttributes) {
        self = .init(
            protocolInstanceID: rawValue.protocolInstanceID,
            rejectedRequestMessageID: rawValue.rejectedRequestMessageID,
            rejectedRequestSequencingEventID: Int(rawValue.rejectedRequestSequencingEventID),
            rejectedRequest: .init(rawValue.rejectedRequest),
            failure: .init(temporalAPIFailure: rawValue.failure)
        )
    }
}

extension HistoryEvent.Attributes.WorkflowExecutionUpdateCompleted {
    init(_ rawValue: Temporal_Api_History_V1_WorkflowExecutionUpdateCompletedEventAttributes) {
        self = .init(
            meta: .init(rawValue.meta),
            acceptedEventID: Int(rawValue.acceptedEventID),
            outcome: .init(rawValue.outcome)
        )
    }
}

extension HistoryEvent.Attributes.WorkflowPropertiesModifiedExternally {
    init(_ rawValue: Temporal_Api_History_V1_WorkflowPropertiesModifiedExternallyEventAttributes) {
        self = .init(
            newTaskQueue: rawValue.newTaskQueue.nilIfEmpty,
            newWorkflowTaskTimeout: rawValue.hasNewWorkflowTaskTimeout ? .init(rawValue.newWorkflowTaskTimeout) : nil,
            newWorkflowRunTimeout: rawValue.hasNewWorkflowRunTimeout ? .init(rawValue.newWorkflowRunTimeout) : nil,
            newWorkflowExecutionTimeout: rawValue.hasNewWorkflowExecutionTimeout ? .init(rawValue.newWorkflowExecutionTimeout) : nil,
            upsertedMemo: rawValue.upsertedMemo.fields.mapValues { .init(temporalAPIPayload: $0) }
        )
    }
}

extension HistoryEvent.Attributes.ActivityPropertiesModifiedExternally {
    init(_ rawValue: Temporal_Api_History_V1_ActivityPropertiesModifiedExternallyEventAttributes) {
        self = .init(
            scheduledEventID: Int(rawValue.scheduledEventID),
            newRetryPolicy: .init(retryPolicy: rawValue.newRetryPolicy)
        )
    }
}

extension HistoryEvent.Attributes.WorkflowPropertiesModified {
    init(_ rawValue: Temporal_Api_History_V1_WorkflowPropertiesModifiedEventAttributes) {
        self = .init(
            workflowTaskCompletedEventID: Int(rawValue.workflowTaskCompletedEventID),
            upsertedMemo: rawValue.upsertedMemo.fields.mapValues { .init(temporalAPIPayload: $0) }
        )
    }
}

extension HistoryEvent.Attributes.WorkflowExecutionUpdateAdmitted {
    init(_ rawValue: Temporal_Api_History_V1_WorkflowExecutionUpdateAdmittedEventAttributes) {
        self = .init(
            request: .init(rawValue.request),
            origin: .init(rawValue.origin)
        )
    }
}

extension HistoryEvent.Attributes.NexusOperationScheduled {
    init(_ rawValue: Temporal_Api_History_V1_NexusOperationScheduledEventAttributes) {
        self = .init(
            endpoint: rawValue.endpoint,
            service: rawValue.service,
            operation: rawValue.operation,
            input: .init(temporalAPIPayload: rawValue.input),
            scheduleToCloseTimeout: rawValue.hasScheduleToCloseTimeout ? .init(rawValue.scheduleToCloseTimeout) : nil,
            nexusHeader: rawValue.nexusHeader,
            workflowTaskCompletedEventID: Int(rawValue.workflowTaskCompletedEventID),
            requestID: rawValue.requestID,
            endpointID: rawValue.endpointID
        )
    }
}

extension HistoryEvent.Attributes.NexusOperationStarted {
    init(_ rawValue: Temporal_Api_History_V1_NexusOperationStartedEventAttributes) {
        self = .init(
            scheduledEventID: Int(rawValue.scheduledEventID),
            operationID: rawValue.operationID,
            requestID: rawValue.requestID,
            operationToken: rawValue.operationToken
        )
    }
}

extension HistoryEvent.Attributes.NexusOperationCompleted {
    init(_ rawValue: Temporal_Api_History_V1_NexusOperationCompletedEventAttributes) {
        self = .init(
            scheduledEventID: Int(rawValue.scheduledEventID),
            result: .init(temporalAPIPayload: rawValue.result),
            requestID: rawValue.requestID
        )
    }
}

extension HistoryEvent.Attributes.NexusOperationFailed {
    init(_ rawValue: Temporal_Api_History_V1_NexusOperationFailedEventAttributes) {
        self = .init(
            scheduledEventID: Int(rawValue.scheduledEventID),
            failure: .init(temporalAPIFailure: rawValue.failure),
            requestID: rawValue.requestID
        )
    }
}

extension HistoryEvent.Attributes.NexusOperationCanceled {
    init(_ rawValue: Temporal_Api_History_V1_NexusOperationCanceledEventAttributes) {
        self = .init(
            scheduledEventID: Int(rawValue.scheduledEventID),
            failure: .init(temporalAPIFailure: rawValue.failure),
            requestID: rawValue.requestID
        )
    }
}

extension HistoryEvent.Attributes.NexusOperationTimedOut {
    init(_ rawValue: Temporal_Api_History_V1_NexusOperationTimedOutEventAttributes) {
        self = .init(
            scheduledEventID: Int(rawValue.scheduledEventID),
            failure: .init(temporalAPIFailure: rawValue.failure),
            requestID: rawValue.requestID
        )
    }
}

extension HistoryEvent.Attributes.NexusOperationCancelRequested {
    init(_ rawValue: Temporal_Api_History_V1_NexusOperationCancelRequestedEventAttributes) {
        self = .init(
            scheduledEventID: Int(rawValue.scheduledEventID),
            workflowTaskCompletedEventID: Int(rawValue.workflowTaskCompletedEventID),
        )
    }
}

extension HistoryEvent.Attributes.NexusOperationCancelRequestCompletedEventAttributes {
    init(_ rawValue: Temporal_Api_History_V1_NexusOperationCancelRequestCompletedEventAttributes) {
        self = .init(
            requestedEventID: rawValue.requestedEventID,
            workflowTaskCompletedEventID: rawValue.workflowTaskCompletedEventID,
            scheduledEventID: rawValue.scheduledEventID
        )
    }
}

extension HistoryEvent.Attributes.NexusOperationCancelRequestFailedEventAttributes {
    init(_ rawValue: Temporal_Api_History_V1_NexusOperationCancelRequestFailedEventAttributes) {
        self = .init(
            requestedEventID: rawValue.requestedEventID,
            workflowTaskCompletedEventID: rawValue.workflowTaskCompletedEventID,
            failure: .init(temporalAPIFailure: rawValue.failure),
            scheduledEventID: rawValue.scheduledEventID
        )
    }
}

extension HistoryEvent.Attributes.WorkflowExecutionOptionsUpdated {
    init(_ rawValue: Temporal_Api_History_V1_WorkflowExecutionOptionsUpdatedEventAttributes) {
        self = .init(
            versioningOverride: .init(rawValue.versioningOverride),
            unsetVersioningOverride: rawValue.unsetVersioningOverride,
            attachedRequestID: rawValue.attachedRequestID.nilIfEmpty,
            attachedCompletionCallbacks: rawValue.attachedCompletionCallbacks.map { .init($0) }
        )
    }
}

extension String {
    fileprivate var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
