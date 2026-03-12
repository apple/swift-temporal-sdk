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
import SwiftProtobuf
import Temporal
import Testing

@Suite(.tags(.workflowTests))
struct WorkflowOptionsTests {
    @Test(
        "WorkflowOptions",
        arguments: [
            WorkflowOptions(id: UUID().uuidString, taskQueue: "test-queue"),
            WorkflowOptions(
                id: UUID().uuidString,
                taskQueue: "test-queue",
                idReusePolicy: .allowDuplicateFailedOnly,
                idConflictPolicy: .useExisting
            ),
            WorkflowOptions(
                id: UUID().uuidString,
                taskQueue: "test-queue",
                idReusePolicy: .rejectDuplicate,
                idConflictPolicy: .terminateExisting
            ),
            WorkflowOptions(
                id: UUID().uuidString,
                taskQueue: "test-queue",
                executionTimeOut: .seconds(2)
            ),
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

        let request = try await Api.Workflowservice.V1.StartWorkflowExecutionRequest(
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
        #expect(request.workflowIDReusePolicy == options.idReusePolicy)
        #expect(request.workflowIDConflictPolicy == options.idConflictPolicy)

        if let timeout = options.executionTimeOut {
            #expect(request.workflowExecutionTimeout.seconds == timeout.components.seconds)
        } else {
            #expect(!request.hasWorkflowExecutionTimeout)
        }

        if let retryPolicy = options.retryPolicy {
            #expect(RetryPolicy(retryPolicy: request.retryPolicy) == retryPolicy)
        } else {
            #expect(!request.hasRetryPolicy)
        }
    }

    @Test("WorkflowOptions with runTimeout")
    func testRunTimeout() async throws {
        let options = WorkflowOptions(
            id: UUID().uuidString,
            taskQueue: "test-queue",
            runTimeout: .seconds(30)
        )

        let request = try await Api.Workflowservice.V1.StartWorkflowExecutionRequest(
            namespace: "default",
            identity: "test-identity",
            requestID: "test-request",
            workflowTypeName: "TestWorkflow",
            workflowOptions: options,
            dataConverter: .default,
            headers: [:],
            inputs: []
        )

        #expect(request.hasWorkflowRunTimeout)
        #expect(request.workflowRunTimeout.seconds == 30)
    }

    @Test("WorkflowOptions with taskTimeout")
    func testTaskTimeout() async throws {
        let options = WorkflowOptions(
            id: UUID().uuidString,
            taskQueue: "test-queue",
            taskTimeout: .seconds(10)
        )

        let request = try await Api.Workflowservice.V1.StartWorkflowExecutionRequest(
            namespace: "default",
            identity: "test-identity",
            requestID: "test-request",
            workflowTypeName: "TestWorkflow",
            workflowOptions: options,
            dataConverter: .default,
            headers: [:],
            inputs: []
        )

        #expect(request.hasWorkflowTaskTimeout)
        #expect(request.workflowTaskTimeout.seconds == 10)
    }

    @Test("WorkflowOptions with startDelay")
    func testStartDelay() async throws {
        let options = WorkflowOptions(
            id: UUID().uuidString,
            taskQueue: "test-queue",
            startDelay: .seconds(5)
        )

        let request = try await Api.Workflowservice.V1.StartWorkflowExecutionRequest(
            namespace: "default",
            identity: "test-identity",
            requestID: "test-request",
            workflowTypeName: "TestWorkflow",
            workflowOptions: options,
            dataConverter: .default,
            headers: [:],
            inputs: []
        )

        #expect(request.hasWorkflowStartDelay)
        #expect(request.workflowStartDelay.seconds == 5)
    }

    @Test("WorkflowOptions with cronSchedule")
    func testCronSchedule() async throws {
        let options = WorkflowOptions(
            id: UUID().uuidString,
            taskQueue: "test-queue",
            cronSchedule: "0 * * * *"
        )

        let request = try await Api.Workflowservice.V1.StartWorkflowExecutionRequest(
            namespace: "default",
            identity: "test-identity",
            requestID: "test-request",
            workflowTypeName: "TestWorkflow",
            workflowOptions: options,
            dataConverter: .default,
            headers: [:],
            inputs: []
        )

        #expect(request.cronSchedule == "0 * * * *")
    }

    @Test("WorkflowOptions with requestEagerStart")
    func testRequestEagerStart() async throws {
        let options = WorkflowOptions(
            id: UUID().uuidString,
            taskQueue: "test-queue",
            requestEagerStart: true
        )

        let request = try await Api.Workflowservice.V1.StartWorkflowExecutionRequest(
            namespace: "default",
            identity: "test-identity",
            requestID: "test-request",
            workflowTypeName: "TestWorkflow",
            workflowOptions: options,
            dataConverter: .default,
            headers: [:],
            inputs: []
        )

        #expect(request.requestEagerExecution == true)
    }

    @Test("WorkflowOptions requestEagerStart defaults to false")
    func testRequestEagerStartDefault() async throws {
        let options = WorkflowOptions(
            id: UUID().uuidString,
            taskQueue: "test-queue"
        )

        let request = try await Api.Workflowservice.V1.StartWorkflowExecutionRequest(
            namespace: "default",
            identity: "test-identity",
            requestID: "test-request",
            workflowTypeName: "TestWorkflow",
            workflowOptions: options,
            dataConverter: .default,
            headers: [:],
            inputs: []
        )

        #expect(request.requestEagerExecution == false)
    }

    @Test("WorkflowOptions with staticSummary and staticDetails")
    func testStaticSummaryAndDetails() async throws {
        let options = WorkflowOptions(
            id: UUID().uuidString,
            taskQueue: "test-queue",
            staticSummary: "My workflow summary",
            staticDetails: "My workflow details\nwith multiple lines"
        )

        let request = try await Api.Workflowservice.V1.StartWorkflowExecutionRequest(
            namespace: "default",
            identity: "test-identity",
            requestID: "test-request",
            workflowTypeName: "TestWorkflow",
            workflowOptions: options,
            dataConverter: .default,
            headers: [:],
            inputs: []
        )

        #expect(request.hasUserMetadata)
        #expect(request.userMetadata.hasSummary)
        #expect(request.userMetadata.hasDetails)
    }

    @Test("WorkflowOptions with priority")
    func testPriority() async throws {
        let priority = Priority(priorityKey: 1)

        let options = WorkflowOptions(
            id: UUID().uuidString,
            taskQueue: "test-queue",
            priority: priority
        )

        let request = try await Api.Workflowservice.V1.StartWorkflowExecutionRequest(
            namespace: "default",
            identity: "test-identity",
            requestID: "test-request",
            workflowTypeName: "TestWorkflow",
            workflowOptions: options,
            dataConverter: .default,
            headers: [:],
            inputs: []
        )

        #expect(request.hasPriority)
        #expect(request.priority.priorityKey == 1)
    }

    @Test("WorkflowOptions with versioningOverride")
    func testVersioningOverride() async throws {
        let options = WorkflowOptions(
            id: UUID().uuidString,
            taskQueue: "test-queue",
            versioningOverride: .autoUpgrade
        )

        let request = try await Api.Workflowservice.V1.StartWorkflowExecutionRequest(
            namespace: "default",
            identity: "test-identity",
            requestID: "test-request",
            workflowTypeName: "TestWorkflow",
            workflowOptions: options,
            dataConverter: .default,
            headers: [:],
            inputs: []
        )

        #expect(request.hasVersioningOverride)
        #expect(request.versioningOverride.autoUpgrade == true)
    }

    @Test("WorkflowOptions nil optional fields produce no proto fields")
    func testNilOptionalFieldsProduceNoProtoFields() async throws {
        let options = WorkflowOptions(
            id: UUID().uuidString,
            taskQueue: "test-queue"
        )

        let request = try await Api.Workflowservice.V1.StartWorkflowExecutionRequest(
            namespace: "default",
            identity: "test-identity",
            requestID: "test-request",
            workflowTypeName: "TestWorkflow",
            workflowOptions: options,
            dataConverter: .default,
            headers: [:],
            inputs: []
        )

        #expect(!request.hasWorkflowRunTimeout)
        #expect(!request.hasWorkflowTaskTimeout)
        #expect(!request.hasWorkflowStartDelay)
        #expect(request.cronSchedule.isEmpty)
        #expect(!request.hasUserMetadata)
        #expect(!request.hasPriority)
        #expect(!request.hasVersioningOverride)
    }

    @Test("SignalWithStart proto conversion includes new fields")
    func testSignalWithStartProtoConversion() async throws {
        let priority = Priority(priorityKey: 2)

        let options = WorkflowOptions(
            id: UUID().uuidString,
            taskQueue: "test-queue",
            runTimeout: .seconds(60),
            taskTimeout: .seconds(10),
            startDelay: .seconds(5),
            cronSchedule: "*/5 * * * *",
            staticSummary: "Signal workflow",
            priority: priority
        )

        let request = try await Api.Workflowservice.V1.SignalWithStartWorkflowExecutionRequest(
            namespace: "default",
            identity: "test-identity",
            requestID: "test-request",
            workflowTypeName: "TestWorkflow",
            workflowOptions: options,
            dataConverter: .default,
            headers: [:],
            inputs: [],
            signalName: "test-signal",
            signalInput: []
        )

        #expect(request.hasWorkflowRunTimeout)
        #expect(request.workflowRunTimeout.seconds == 60)
        #expect(request.hasWorkflowTaskTimeout)
        #expect(request.workflowTaskTimeout.seconds == 10)
        #expect(request.hasWorkflowStartDelay)
        #expect(request.workflowStartDelay.seconds == 5)
        #expect(request.cronSchedule == "*/5 * * * *")
        #expect(request.hasUserMetadata)
        #expect(request.hasPriority)
        #expect(request.priority.priorityKey == 2)
    }
}
