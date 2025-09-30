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

// Worker Workflow Inbound interceptor attributes
extension Span {
    func setWorkerExecuteWorkflowSpanAttributes(info: WorkflowInfo) {
        self.attributes[TemporalTracingKeys.workflowAttempt] = info.attempt
        self.attributes[TemporalTracingKeys.workflowStartTime] = info.startTime.description
        self.attributes[TemporalTracingKeys.workflowName] = info.workflowName
        self.attributes[TemporalTracingKeys.workflowId] = info.workflowID
        self.attributes[TemporalTracingKeys.workflowType] = info.workflowType
        self.attributes[TemporalTracingKeys.workflowRunId] = info.runID
        self.attributes[TemporalTracingKeys.workflowContinuedRunId] = info.continuedRunID
        self.attributes[TemporalTracingKeys.workflowTaskQueue] = info.taskQueue
        self.attributes[TemporalTracingKeys.workflowNamespace] = info.namespace
        self.attributes[TemporalTracingKeys.workflowCronSchedule] = info.cronSchedule
        if let runTimeout = info.runTimeout {
            self.attributes[TemporalTracingKeys.workflowRunTimeout] = runTimeout.description
        }
        if let taskTimeout = info.taskTimeout {
            self.attributes[TemporalTracingKeys.workflowTaskTimeout] = taskTimeout.description
        }
        if let executionTimeout = info.executionTimeout {
            self.attributes[TemporalTracingKeys.workflowExecutionTimeout] = executionTimeout.description
        }
        if let lastFailure = info.lastFailure {
            self.attributes[TemporalTracingKeys.workflowLastFailure] = "\(lastFailure)"
        }
        if let parent = info.parent {
            self.attributes[TemporalTracingKeys.workflowParentId] = parent.workflowID
            self.attributes[TemporalTracingKeys.workflowParentRunId] = parent.runID
            self.attributes[TemporalTracingKeys.workflowParentNamespace] = parent.namespace
        }
        if let retryPolicy = info.retryPolicy {
            self.attributes[TemporalTracingKeys.workflowRetryPolicyMaximumAttempts] = retryPolicy.maximumAttempts.description
            self.attributes[TemporalTracingKeys.workflowRetryPolicyBackOffCoefficient] = retryPolicy.backoffCoefficient.description
            if let initialInterval = retryPolicy.initialInterval {
                self.attributes[TemporalTracingKeys.workflowRetryPolicyInitialInterval] = initialInterval.description
            }
            if let maximumInterval = retryPolicy.maximumInterval {
                self.attributes[TemporalTracingKeys.workflowRetryPolicyMaximumInterval] = maximumInterval.description
            }
        }

        // do not record last results or headers
    }

    func setWorkerHandleSignalSpanAttributes(signalName: String, workflowInfo: WorkflowInfo) {
        self.attributes[TemporalTracingKeys.workflowSignalName] = signalName
        self.setWorkerExecuteWorkflowSpanAttributes(info: workflowInfo)
    }

    func setWorkerHandleQuerySpanAttributes(queryId: String, queryName: String, workflowInfo: WorkflowInfo) {
        self.attributes[TemporalTracingKeys.workflowQueryId] = queryId
        self.attributes[TemporalTracingKeys.workflowQueryName] = queryName
        self.setWorkerExecuteWorkflowSpanAttributes(info: workflowInfo)
    }

    func setWorkerHandleUpdateSpanAttributes(updateId: String, updateName: String, workflowInfo: WorkflowInfo) {
        self.attributes[TemporalTracingKeys.workflowUpdateId] = updateId
        self.attributes[TemporalTracingKeys.workflowUpdateName] = updateName
        self.setWorkerExecuteWorkflowSpanAttributes(info: workflowInfo)
    }
}
