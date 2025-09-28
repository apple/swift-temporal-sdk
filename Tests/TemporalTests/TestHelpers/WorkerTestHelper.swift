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

import Foundation
import Logging
import ServiceLifecycle
import Temporal
import TemporalTestKit
import Testing

import protocol GRPCCore.ClientTransport

@Suite(.temporalTestServer, .temporalTimeSkippingTestServer, .timeLimit(.minutes(1)))
enum TestServerDependentTests {}

public func withTestClient<Result: Sendable>(
    _ body: (TemporalClient) async throws -> Result
) async throws -> Result {
    let logger: Logger = {
        var logger = Logger(label: "TestClient", factory: { StreamLogHandler.standardOutput(label: $0) })
        logger.logLevel = .info
        return logger
    }()

    return try await TemporalTestServer.testServer!.withConnectedClient(logger: logger) { client, _, _ in
        try await body(client)
    }
}

func withTestClient<Result: Sendable>(
    namespace: String = "default",
    label: String = UUID().uuidString,
    logger: Logger = {
        var logger = Logger(label: "TestClient", factory: { StreamLogHandler.standardOutput(label: $0) })
        logger.logLevel = .info
        return logger
    }(),
    isolation: isolated (any Actor)? = #isolation,
    _ body: (TemporalClient) async throws -> Result
) async throws -> Result {
    try await TemporalTestServer.testServer!.withConnectedClient(logger: logger) { client, host, port in
        try await body(client)
    }
}

func withTestWorkerAndClient<Result: Sendable, Worker: TemporalWorkerProtocol>(
    namespace: String = "default",
    taskQueue: String = UUID().uuidString,
    workerBuildID: String = "",
    maxHeartbeatThrottleInterval: Duration = .seconds(60),
    interceptors: [any WorkerInterceptor] = [],
    clientInterceptors: [any ClientInterceptor] = [],
    activities: [any ActivityDefinition] = [],
    workflows: [any WorkflowDefinition.Type] = [],
    workerType: Worker.Type = TemporalWorker.self,
    clientLogger: Logger = {
        var logger = Logger(label: "TestClient", factory: { StreamLogHandler.standardOutput(label: $0) })
        logger.logLevel = .info
        return logger
    }(),
    workerLogger: Logger = {
        var logger = Logger(label: "TestWorker", factory: { StreamLogHandler.standardOutput(label: $0) })
        logger.logLevel = .info
        return logger
    }(),
    isolation: isolated (any Actor)? = #isolation,
    _ body: sending @escaping @isolated(any) (String, TemporalClient) async throws -> sending Result
) async throws -> Result {
    try await TemporalTestServer.testServer!.withConnectedWorker(
        namespace: namespace,
        taskQueue: taskQueue,
        workerBuildID: workerBuildID,
        maxHeartbeatThrottleInterval: maxHeartbeatThrottleInterval,
        interceptors: interceptors,
        activities: activities,
        workflows: workflows,
        workerType: workerType,
        logger: workerLogger
    ) { worker in
        try await TemporalTestServer.testServer!.withConnectedClient(
            logger: clientLogger,
            interceptors: clientInterceptors
        ) { client, _, _ in
            try await body(taskQueue, client)
        }
    }
}

func withTimeSkippingTestWorkerAndClient<Result: Sendable, Worker: TemporalWorkerProtocol>(
    namespace: String = "default",
    taskQueue: String = UUID().uuidString,
    workerBuildID: String = "",
    maxHeartbeatThrottleInterval: Duration = .seconds(60),
    interceptors: [any WorkerInterceptor] = [],
    clientInterceptors: [any ClientInterceptor] = [],
    activities: [any ActivityDefinition] = [],
    workflows: [any WorkflowDefinition.Type] = [],
    workerType: Worker.Type = TemporalWorker.self,
    clientLogger: Logger = {
        var logger = Logger(label: "TestClient", factory: { StreamLogHandler.standardOutput(label: $0) })
        logger.logLevel = .info
        return logger
    }(),
    workerLogger: Logger = {
        var logger = Logger(label: "TestWorker", factory: { StreamLogHandler.standardOutput(label: $0) })
        logger.logLevel = .info
        return logger
    }(),
    isolation: isolated (any Actor)? = #isolation,
    _ body: sending @escaping @isolated(any) (String, TemporalClient) async throws -> sending Result
) async throws -> Result {
    try await TemporalTestServer.timeSkippingTestServer!.withConnectedWorker(
        namespace: namespace,
        taskQueue: taskQueue,
        workerBuildID: workerBuildID,
        maxHeartbeatThrottleInterval: maxHeartbeatThrottleInterval,
        interceptors: interceptors,
        activities: activities,
        workflows: workflows,
        workerType: workerType,
        logger: workerLogger
    ) { worker in
        try await TemporalTestServer.timeSkippingTestServer!.withConnectedClient(
            logger: clientLogger,
            interceptors: clientInterceptors
        ) { client, _, _ in
            try await body(taskQueue, client)
        }
    }
}

func executeWorkflow<Workflow: WorkflowDefinition>(
    _ workflowType: Workflow.Type = Workflow.self,
    input: sending Workflow.Input,
    workflowExecutionTimeout: Duration? = nil,
    workflowRetryPolicy: RetryPolicy? = nil,
    activities: [any ActivityDefinition] = [],
    moreWorkflows: [any WorkflowDefinition.Type] = [],
    searchAttributes: SearchAttributeCollection = .init(),
    taskQueue: String = "tq-\(UUID().uuidString)",
    id: String = "wf-\(UUID().uuidString)",
    memo: [String: any Sendable] = [:],
    interceptors: [any WorkerInterceptor] = [],
    clientInterceptors: [any ClientInterceptor] = [],
    clientLogger: Logger = {
        var logger = Logger(label: "TestClient", factory: { StreamLogHandler.standardOutput(label: $0) })
        logger.logLevel = .info
        return logger
    }(),
    workerLogger: Logger = {
        var logger = Logger(label: "TestWorker", factory: { StreamLogHandler.standardOutput(label: $0) })
        logger.logLevel = .info
        return logger
    }(),
    body: sending (@isolated(any) (WorkflowHandle<Workflow>, Workflow.Output) async throws -> Void)? = nil
) async throws -> Workflow.Output where Workflow.Output: Sendable {
    try await workflowHandle(
        for: workflowType,
        input: input,
        workflowExecutionTimeout: workflowExecutionTimeout,
        workflowRetryPolicy: workflowRetryPolicy,
        activities: activities,
        moreWorkflows: moreWorkflows,
        searchAttributes: searchAttributes,
        taskQueue: taskQueue,
        id: id,
        memo: memo,
        interceptors: interceptors,
        clientInterceptors: clientInterceptors,
        clientLogger: clientLogger,
        workerLogger: workerLogger
    ) { handle in
        let result = try await handle.result()

        try await body?(handle, result)

        return result
    }
}

@discardableResult
func workflowHandle<Workflow: WorkflowDefinition, R>(
    for workflowType: Workflow.Type = Workflow.self,
    input: Workflow.Input,
    workflowExecutionTimeout: Duration? = nil,
    workflowRetryPolicy: RetryPolicy? = nil,
    activities: [any ActivityDefinition] = [],
    moreWorkflows: [any WorkflowDefinition.Type] = [],
    searchAttributes: SearchAttributeCollection = .init(),
    taskQueue: String = "tq-\(UUID().uuidString)",
    id: String = "wf-\(UUID().uuidString)",
    memo: [String: any Sendable] = [:],
    interceptors: [any WorkerInterceptor] = [],
    clientInterceptors: [any ClientInterceptor] = [],
    clientLogger: Logger = {
        var logger = Logger(label: "TestClient", factory: { StreamLogHandler.standardOutput(label: $0) })
        logger.logLevel = .info
        return logger
    }(),
    workerLogger: Logger = {
        var logger = Logger(label: "TestWorker", factory: { StreamLogHandler.standardOutput(label: $0) })
        logger.logLevel = .info
        return logger
    }(),
    body: sending @escaping @isolated(any) (WorkflowHandle<Workflow>) async throws -> sending R
) async throws -> R where Workflow.Output: Sendable, R: Sendable {
    var workflowOptions = WorkflowOptions(id: id, taskQueue: taskQueue)
    workflowOptions.executionTimeOut = workflowExecutionTimeout
    workflowOptions.retryPolicy = workflowRetryPolicy
    workflowOptions.memo = memo
    workflowOptions.searchAttributes = searchAttributes
    let namespace = "default"
    return try await withTestWorkerAndClient(
        namespace: namespace,
        taskQueue: taskQueue,
        workerBuildID: "",
        interceptors: interceptors,
        clientInterceptors: clientInterceptors,
        activities: activities,
        workflows: [workflowType] + moreWorkflows,
        clientLogger: clientLogger,
        workerLogger: workerLogger,
    ) { taskQueue, client in
        let handle = try await client.startWorkflow(
            type: workflowType,
            options: workflowOptions,
            input: input
        )
        return try await body(handle)
    }
}

@discardableResult
func scheduleHandle<Workflow: WorkflowDefinition, R>(
    workflowType: Workflow.Type = Workflow.self,
    schedule: Schedule<Workflow.Input>,
    options: ScheduleOptions? = nil,
    workflowExecutionTimeout: Duration? = nil,
    workflowRetryPolicy: RetryPolicy? = nil,
    activities: [any ActivityDefinition] = [],
    moreWorkflows: [any WorkflowDefinition.Type] = [],
    taskQueue: String = "tq-\(UUID().uuidString)",
    id: String = "sc-\(UUID().uuidString)",
    memo: [String: any Sendable] = [:],
    interceptors: [any WorkerInterceptor] = [],
    body: sending @escaping @isolated(any) (ScheduleHandle<Workflow>) async throws -> R
) async throws -> R where R: Sendable {
    var workflowOptions = WorkflowOptions(id: id, taskQueue: taskQueue)
    workflowOptions.executionTimeOut = workflowExecutionTimeout
    workflowOptions.retryPolicy = workflowRetryPolicy
    workflowOptions.memo = memo

    return try await withTestWorkerAndClient(
        namespace: "default",
        taskQueue: taskQueue,
        workerBuildID: "",
        interceptors: interceptors,
        activities: activities,
        workflows: [Workflow.self] + moreWorkflows
    ) { _, client in
        let scheduleHandle = try await client.createSchedule(
            id: id,
            workflowType: workflowType,
            schedule: schedule,
            options: options
        )

        return try await body(scheduleHandle)
    }
}
