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

import Tracing

// Worker Workflow Outbound interceptor attributes
extension Span {
    func setWorkerSignalWorkflowSpanAttributes(workflowID: String, signalName: String) {
        self.attributes[TemporalTracingKeys.workflowId] = workflowID
        self.attributes[TemporalTracingKeys.workflowSignalName] = signalName
    }

    func setWorkerStartChildWorkflowRequestSpanAttributes(workflowInfo: WorkflowInfo, options: ChildWorkflowOptions) {
        if let childId = options.id {
            self.attributes[TemporalTracingKeys.workflowId] = childId
        }
        if let childTaskQueue = options.taskQueue {
            self.attributes[TemporalTracingKeys.workflowTaskQueue] = childTaskQueue
        }
        if let childRetryPolicy = options.retryPolicy {
            self.attributes[TemporalTracingKeys.workflowRetryPolicyMaximumAttempts] = childRetryPolicy.maximumAttempts.description
            self.attributes[TemporalTracingKeys.workflowRetryPolicyBackOffCoefficient] = childRetryPolicy.backoffCoefficient.description
            if let initialInterval = childRetryPolicy.initialInterval {
                self.attributes[TemporalTracingKeys.workflowRetryPolicyInitialInterval] = initialInterval.description
            }
            if let maximumInterval = childRetryPolicy.maximumInterval {
                self.attributes[TemporalTracingKeys.workflowRetryPolicyMaximumInterval] = maximumInterval.description
            }
        }
        if let childExecutionTimeout = options.executionTimeout {
            self.attributes[TemporalTracingKeys.workflowExecutionTimeout] = childExecutionTimeout.description
        }
        if let childRunTimeout = options.runTimeout {
            self.attributes[TemporalTracingKeys.workflowRunTimeout] = childRunTimeout.description
        }
        if let childTaskTimeout = options.taskTimeout {
            self.attributes[TemporalTracingKeys.workflowTaskTimeout] = childTaskTimeout.description
        }
        // swift-format-ignore: ReplaceForEachWithForLoop
        options.searchAttributes?.forEach { key, value in
            if let value {
                self.attributes["\(TemporalTracingKeys.workflowSearchAttributesPrefix)\(key.name) (\(key.type.indexedValueTypeString))"] = "\(value)"
            }
        }
        self.attributes[TemporalTracingKeys.workflowParentClosePolicy] = options.parentClosePolicy.description
        self.attributes[TemporalTracingKeys.workflowIdReusePolicy] = options.idReusePolicy.description
        if let childCronSchedule = options.cronSchedule {
            self.attributes[TemporalTracingKeys.workflowCronSchedule] = childCronSchedule
        }
        self.attributes[TemporalTracingKeys.workflowCancellationType] = options.cancellationType.description
        self.attributes[TemporalTracingKeys.workflowVersioningIntent] = options.versioningIntent.description

        self.setWorkerExecuteWorkflowSpanAttributes(info: workflowInfo)
    }

    func setWorkerStartChildWorkflowResponseSpanAttributes(childHandle: UntypedChildWorkflowHandle) {
        self.attributes[TemporalTracingKeys.workflowId] = childHandle.id
        self.attributes[TemporalTracingKeys.workflowFirstExecutionRunId] = childHandle.firstExecutionRunID
    }

    func setWorkerContinueAsNewRequestSpanAttributes(
        workflowInfo: WorkflowInfo,
        options: ContinueAsNewOptions
    ) {
        self.setWorkerExecuteWorkflowSpanAttributes(info: workflowInfo)

        if let taskQueue = options.taskQueue {
            self.attributes[TemporalTracingKeys.workflowTaskQueue] = taskQueue
        }
        if let taskTimeout = options.taskTimeout {
            self.attributes[TemporalTracingKeys.workflowTaskTimeout] = taskTimeout.description
        }
        if let runDuration = options.runTimeout {
            self.attributes[TemporalTracingKeys.workflowRunTimeout] = runDuration.description
        }
        if let retryPolicy = options.retryPolicy {
            self.attributes[TemporalTracingKeys.workflowRetryPolicyMaximumAttempts] = retryPolicy.maximumAttempts.description
            self.attributes[TemporalTracingKeys.workflowRetryPolicyBackOffCoefficient] = retryPolicy.backoffCoefficient.description
            if let initialInterval = retryPolicy.initialInterval {
                self.attributes[TemporalTracingKeys.workflowRetryPolicyInitialInterval] = initialInterval.description
            }
            if let maximumInterval = retryPolicy.maximumInterval {
                self.attributes[TemporalTracingKeys.workflowRetryPolicyMaximumInterval] = maximumInterval.description
            }
        }
        // swift-format-ignore: ReplaceForEachWithForLoop
        options.searchAttributes?.forEach { key, value in
            if let value {
                self.attributes["\(TemporalTracingKeys.workflowSearchAttributesPrefix)\(key.name) (\(key.type.indexedValueTypeString))"] = "\(value)"
            }
        }
    }

    func setWorkerHandleSleepSpanAttributes(sleepInput: HandleSleepInput) {
        self.attributes[TemporalTracingKeys.workflowSleepDuration] = sleepInput.duration.description
        if let summary = sleepInput.summary {
            self.attributes[TemporalTracingKeys.workflowSleepSummary] = summary
        }
        self.setWorkerExecuteWorkflowSpanAttributes(info: Workflow.info)
    }

    func setWorkerExecuteActivityRequestSpanAttributes(
        workflowInfo: WorkflowInfo,
        activityName: String,
        activityOptions: ActivityOptions
    ) {
        self.attributes[TemporalTracingKeys.activityName] = activityName

        // Activity ID, if provided
        if let actId = activityOptions.activityID {
            self.attributes[TemporalTracingKeys.activityID] = actId
        }

        // Disable eager execution flag
        self.attributes[TemporalTracingKeys.activityDisableEagerExecution] =
            activityOptions.disableEagerActivityExecution.description

        // Cancellation type
        self.attributes[TemporalTracingKeys.activityCancellationType] =
            activityOptions.cancellationType.description

        // Heartbeat timeout
        if let heartbeat = activityOptions.heartbeatTimeout {
            self.attributes[TemporalTracingKeys.activityHeartbeatTimeout] =
                heartbeat.description
        }

        // Schedule-to-close timeout
        if let scheduleToClose = activityOptions.scheduleToCloseTimeout {
            self.attributes[TemporalTracingKeys.activityScheduleToCloseTimeout] =
                scheduleToClose.description
        }

        // Schedule-to-start timeout
        if let scheduleToStart = activityOptions.scheduleToStartTimeout {
            self.attributes[TemporalTracingKeys.activityScheduleToStartTimeout] =
                scheduleToStart.description
        }

        // Start-to-close timeout
        if let startToClose = activityOptions.startToCloseTimeout {
            self.attributes[TemporalTracingKeys.activityStartToCloseTimeout] =
                startToClose.description
        }

        // Task queue, if provided
        if let queue = activityOptions.taskQueue {
            self.attributes[TemporalTracingKeys.activityTaskQueue] = queue
        }

        // Retry policy
        if let retryPolicy = activityOptions.retryPolicy {
            self.attributes[TemporalTracingKeys.activityRetryPolicyMaximumAttempts] =
                retryPolicy.maximumAttempts.description
            self.attributes[TemporalTracingKeys.activityRetryPolicyBackoffCoefficient] =
                retryPolicy.backoffCoefficient.description
            if let initialInterval = retryPolicy.initialInterval {
                self.attributes[TemporalTracingKeys.activityRetryPolicyInitialInterval] =
                    initialInterval.description
            }
            if let maximumInterval = retryPolicy.maximumInterval {
                self.attributes[TemporalTracingKeys.activityRetryPolicyMaximumInterval] =
                    maximumInterval.description
            }
        }

        // Versioning intent
        self.attributes[TemporalTracingKeys.activityVersioningIntent] =
            activityOptions.versioningIntent.description

        self.setWorkerExecuteWorkflowSpanAttributes(info: workflowInfo)
    }

    func setWorkerExecuteLocalActivityRequestSpanAttributes(
        workflowInfo: WorkflowInfo,
        activityName: String,
        activityOptions: LocalActivityOptions
    ) {
        self.attributes[TemporalTracingKeys.activityName] = activityName

        // Cancellation type
        self.attributes[TemporalTracingKeys.activityCancellationType] =
            activityOptions.cancellationType.description

        // Schedule-to-close timeout
        if let scheduleToClose = activityOptions.scheduleToCloseTimeout {
            self.attributes[TemporalTracingKeys.activityScheduleToCloseTimeout] =
                scheduleToClose.description
        }

        // Schedule-to-start timeout
        if let scheduleToStart = activityOptions.scheduleToStartTimeout {
            self.attributes[TemporalTracingKeys.activityScheduleToStartTimeout] =
                scheduleToStart.description
        }

        // Start-to-close timeout
        if let startToClose = activityOptions.startToCloseTimeout {
            self.attributes[TemporalTracingKeys.activityStartToCloseTimeout] =
                startToClose.description
        }

        // Retry policy
        if let retryPolicy = activityOptions.retryPolicy {
            self.attributes[TemporalTracingKeys.activityRetryPolicyMaximumAttempts] =
                retryPolicy.maximumAttempts.description
            self.attributes[TemporalTracingKeys.activityRetryPolicyBackoffCoefficient] =
                retryPolicy.backoffCoefficient.description
            if let initialInterval = retryPolicy.initialInterval {
                self.attributes[TemporalTracingKeys.activityRetryPolicyInitialInterval] =
                    initialInterval.description
            }
            if let maximumInterval = retryPolicy.maximumInterval {
                self.attributes[TemporalTracingKeys.activityRetryPolicyMaximumInterval] =
                    maximumInterval.description
            }
        }

        self.setWorkerExecuteWorkflowSpanAttributes(info: workflowInfo)
    }

    func setWorkerContinueAsNewRespondSpanAttributes(
        continueAsNewError: ContinueAsNewError
    ) {
        self.attributes[TemporalTracingKeys.workflowName] = continueAsNewError.workflowName
        self.attributes[TemporalTracingKeys.workflowTaskQueue] = continueAsNewError.taskQueue

        if let taskTimeout = continueAsNewError.taskTimeout {
            self.attributes[TemporalTracingKeys.workflowTaskTimeout] = taskTimeout.description
        }
        if let runTimeout = continueAsNewError.runTimeout {
            self.attributes[TemporalTracingKeys.workflowRunTimeout] = runTimeout.description
        }

        if let retryPolicy = continueAsNewError.retryPolicy {
            self.attributes[TemporalTracingKeys.workflowRetryPolicyMaximumAttempts] =
                retryPolicy.maximumAttempts.description
            self.attributes[TemporalTracingKeys.workflowRetryPolicyBackOffCoefficient] =
                retryPolicy.backoffCoefficient.description
            if let initialInterval = retryPolicy.initialInterval {
                self.attributes[TemporalTracingKeys.workflowRetryPolicyInitialInterval] =
                    initialInterval.description
            }
            if let maximumInterval = retryPolicy.maximumInterval {
                self.attributes[TemporalTracingKeys.workflowRetryPolicyMaximumInterval] =
                    maximumInterval.description
            }
        }

        // do not record input, memo, headers

        // swift-format-ignore: ReplaceForEachWithForLoop
        continueAsNewError.searchAttributes?.forEach { key, value in
            let typedKey = key.name
            let typeString = key.type.indexedValueTypeString
            let attrKey = "\(TemporalTracingKeys.workflowSearchAttributesPrefix)\(typedKey) (\(typeString))"
            self.attributes[attrKey] = String(describing: value)
        }

        // Error
        self.attributes[TemporalTracingKeys.workflowContinueAsNewExceptionMessage] = continueAsNewError.message
        if let causeError = continueAsNewError.cause {
            self.attributes[TemporalTracingKeys.workflowContinueAsNewExceptionType] = "\(causeError)"
        }
        self.attributes[TemporalTracingKeys.workflowContinueAsNewExceptionStackTrace] = continueAsNewError.stackTrace
    }
}
