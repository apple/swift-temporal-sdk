//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Temporal SDK open source project
//
// Copyright (c) 2025 Apple Inc. and the Swift Temporal SDK project authors
// Licensed under MIT License
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Swift Cassandra Client project authors
//
// SPDX-License-Identifier: MIT
//
//===----------------------------------------------------------------------===//

extension WorkflowInfo {
    init(
        initializeWorkflow: Coresdk_WorkflowActivation_InitializeWorkflow,
        runID: String,
        taskQueue: String,
        namespace: String,
        payloadConverter: any PayloadConverter,
        failureConverter: any FailureConverter
    ) {
        self = .init(
            attempt: Int(initializeWorkflow.attempt),
            startTime: initializeWorkflow.startTime.date,
            workflowName: initializeWorkflow.workflowType,
            workflowID: initializeWorkflow.workflowID,
            workflowType: initializeWorkflow.workflowType,
            runID: runID,
            taskQueue: taskQueue,
            namespace: namespace,
            headers: initializeWorkflow.headers.mapValues { .init(temporalAPIPayload: $0) }
        )
        if !initializeWorkflow.continuedFromExecutionRunID.isEmpty {
            self.continuedRunID = initializeWorkflow.continuedFromExecutionRunID
        }
        if !initializeWorkflow.cronSchedule.isEmpty {
            self.cronSchedule = initializeWorkflow.cronSchedule
        }
        if initializeWorkflow.hasWorkflowRunTimeout {
            self.runTimeout = .init(protobufDuration: initializeWorkflow.workflowRunTimeout)
        }
        if initializeWorkflow.hasWorkflowTaskTimeout {
            self.taskTimeout = .init(protobufDuration: initializeWorkflow.workflowTaskTimeout)
        }
        if initializeWorkflow.hasWorkflowExecutionTimeout {
            self.executionTimeout = .init(protobufDuration: initializeWorkflow.workflowExecutionTimeout)
        }
        if initializeWorkflow.hasContinuedFailure {
            let failure = TemporalFailure(temporalAPIFailure: initializeWorkflow.continuedFailure)
            self.lastFailure = failureConverter.convertTemporalFailure(failure, payloadConverter: payloadConverter)
        }
        if initializeWorkflow.hasLastCompletionResult {
            self.lastResult = initializeWorkflow.lastCompletionResult.payloads.map {
                .init(.init(temporalAPIPayload: $0))
            }
        }
        if initializeWorkflow.hasParentWorkflowInfo {
            let parentWorkflowInfo = initializeWorkflow.parentWorkflowInfo
            self.parent = .init(
                workflowID: parentWorkflowInfo.workflowID,
                runID: parentWorkflowInfo.runID,
                namespace: parentWorkflowInfo.namespace
            )
        }
        if initializeWorkflow.hasRetryPolicy {
            self.retryPolicy = RetryPolicy(retryPolicy: initializeWorkflow.retryPolicy)
        }
    }
}
