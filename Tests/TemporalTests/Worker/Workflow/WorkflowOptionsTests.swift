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

import Foundation
import Temporal
import Testing

@Suite(.tags(.workflowTests))
struct WorkflowOptionsTests {
    @Test(
        "WorkflowOptions",
        arguments: [
            WorkflowOptions(id: UUID().uuidString, taskQueue: "test-queue"),
            WorkflowOptions(id: UUID().uuidString, taskQueue: "test-queue", idReusePolicy: .allowDuplicateFailedOnly, idConflictPolicy: .useExisting),
            WorkflowOptions(id: UUID().uuidString, taskQueue: "test-queue", idReusePolicy: .rejectDuplicate, idConflictPolicy: .terminateExisting),
            WorkflowOptions(id: UUID().uuidString, taskQueue: "test-queue", executionTimeOut: .seconds(2)),
            WorkflowOptions(
                id: UUID().uuidString,
                taskQueue: "test-queue",
                retryPolicy: RetryPolicy(initialInterval: .seconds(2), maximumAttempts: 3)
            ),
            WorkflowOptions(
                id: UUID().uuidString,
                taskQueue: "test-queue",
                retryPolicy: RetryPolicy(nonRetryableErrorTypes: ["TestError"])
            ),
        ]
    )
    func testWorkflowOptions(options: WorkflowOptions) async throws {
        let namespace = "default"
        let identity = "test-identity"
        let requestId = "test-request"
        let workflowType = "TestWorkflow"

        let options = WorkflowOptions(id: UUID().uuidString, taskQueue: "test-queue")

        let request = try await Temporal_Api_Workflowservice_V1_StartWorkflowExecutionRequest(
            namespace: namespace,
            identity: identity,
            requestID: requestId,
            workflowTypeName: workflowType,
            workflowOptions: options,
            dataConverter: .default,
            headers: [:],
            inputs: []
        )

        #expect(request.namespace == namespace)
        #expect(request.identity == identity)
        #expect(request.workflowType.name == workflowType)
        #expect(request.taskQueue.name == options.taskQueue)
        #expect(request.requestID == requestId)
        #expect(WorkflowIDReusePolicy(request.workflowIDReusePolicy) == options.idReusePolicy)
        #expect(WorkflowIDConflictPolicy(request.workflowIDConflictPolicy) == options.idConflictPolicy)

        if let timeout = options.executionTimeOut {
            #expect(Duration(request.workflowExecutionTimeout) == timeout)
        } else {
            #expect(!request.hasWorkflowExecutionTimeout)
        }

        if let retryPolicy = options.retryPolicy {
            #expect(RetryPolicy(retryPolicy: request.retryPolicy) == retryPolicy)
        } else {
            #expect(!request.hasRetryPolicy)
        }
    }
}
