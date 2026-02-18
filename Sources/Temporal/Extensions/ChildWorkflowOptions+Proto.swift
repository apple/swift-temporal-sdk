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

import SwiftProtobuf

extension Coresdk.WorkflowCommands.StartChildWorkflowExecution {
    init(
        sequenceNumber: UInt32,
        namespace: String,
        workflowName: String,
        childWorkflowOptions: ChildWorkflowOptions,
        generatedWorkflowID: String,
        taskQueue: String,
        parentSearchAttributes: SearchAttributeCollection? = nil,
        memo: [String: TemporalPayload]?,
        headers: [String: TemporalPayload],
        inputs: [TemporalPayload]
    ) {
        self = .with {
            $0.seq = sequenceNumber
            $0.namespace = namespace
            $0.workflowID = childWorkflowOptions.id ?? generatedWorkflowID
            $0.workflowType = workflowName
            $0.taskQueue = childWorkflowOptions.taskQueue ?? taskQueue
            $0.input = inputs.map { .init(temporalPayload: $0) }
            $0.parentClosePolicy = .init(parentClosePolicy: childWorkflowOptions.parentClosePolicy)
            $0.workflowIDReusePolicy = .init(workflowIDReusePolicy: childWorkflowOptions.idReusePolicy)
            $0.cancellationType = .init(childWorkflowCancellationType: childWorkflowOptions.cancellationType)
            $0.versioningIntent = .init(versioningIntent: childWorkflowOptions.versioningIntent)
        }

        let parentSearchAttributes = parentSearchAttributes ?? .init()
        let searchAttributes = childWorkflowOptions.searchAttributes ?? .init()
        let mergedAttributes = parentSearchAttributes.merging(searchAttributes) { $1 }
        if !mergedAttributes.isEmpty {
            self.searchAttributes = Api.Common.V1.SearchAttributes(mergedAttributes).indexedFields
        }

        self.headers = headers.mapValues { .init(temporalPayload: $0) }

        if let retryPolicy = childWorkflowOptions.retryPolicy {
            self.retryPolicy = .init(retryPolicy: retryPolicy)
        }

        if let workflowExecutionTimeout = childWorkflowOptions.executionTimeout {
            self.workflowExecutionTimeout = .init(duration: workflowExecutionTimeout)
        }

        if let runTimeout = childWorkflowOptions.runTimeout {
            self.workflowRunTimeout = .init(duration: runTimeout)
        }

        if let taskTimeout = childWorkflowOptions.taskTimeout {
            self.workflowTaskTimeout = .init(duration: taskTimeout)
        }

        if let memo {
            self.memo = memo.mapValues { .init(temporalPayload: $0) }
        }

        if let cronSchedule = childWorkflowOptions.cronSchedule {
            self.cronSchedule = cronSchedule
        }
    }
}
