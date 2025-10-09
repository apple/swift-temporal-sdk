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

#if canImport(Testing)
import GRPCNIOTransportHTTP2Posix
import Logging
import Temporal
import Testing

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// Test server infrastructure providing local Temporal server instances for integration testing scenarios.
///
/// ``TemporalTestServer`` provides managed test server instances that enable
/// integration testing of Temporal workflows and activities. The test server supports both
/// standard real-time execution and time-skipping capabilities for accelerated testing
/// of time-dependent workflow behaviors.
///
/// To support high throughput during parallel testing while avoiding “resource exhausted” error, the Temporal test server
/// is launched with optimized dynamic configuration settings. These values increase request-per-second limits for key services:
/// - `frontend.namespaceRPS` = 5800
/// - `matching.rps` = 5000
/// - `history.rps` = 7000
///
/// ## Usage
///
/// ### Standard test server
///
/// Use the standard test server for functional integration tests:
///
/// ```swift
/// @Test(.temporalTestServer)
/// struct WorkflowIntegrationTests {
///     @Test
///     func testWorkflowExecution() async throws {
///         let testServer = TemporalTestServer.testServer!
///         try await testServer.withConnectedClient(logger: logger) { client in
///             // Test workflow execution against real-time server
///             let handle = try await client.startWorkflow(
///                 MyWorkflow.self,
///                 options: WorkflowOptions(id: "test-workflow")
///             )
///             let result = try await handle.result()
///         }
///     }
/// }
/// ```
///
/// ### Time-skipping test server
///
/// Use the time-skipping server for testing temporal behaviors:
///
/// ```swift
/// @Test(.temporalTimeSkippingTestServer)
/// struct TimeBasedWorkflowTests {
///     @Test
///     func testTimerBasedWorkflow() async throws {
///         let testServer = TemporalTestServer.timeSkippingTestServer!
///         try await testServer.withConnectedClient(logger: logger) { client in
///             // Test workflows with timers and schedules
///             let handle = try await client.startWorkflow(
///                 TimerWorkflow.self,
///                 options: WorkflowOptions(id: "timer-test")
///             )
///             // Time advances automatically for timer-based logic
///             let result = try await handle.result()
///         }
///     }
/// }
/// ```
///
/// ## Test Organization
///
/// For optimal test performance and resource management, group all tests into a single suite using one of the
/// two test traits. This ensures test server instances are properly shared across related tests while maintaining
/// isolation between test suites.
public struct TemporalTestServer: Sendable {
    /// The currently active standard test server instance available within test execution context.
    ///
    /// This task-local variable provides access to the test server when using the
    /// ``TemporalTestServerTrait`` test trait. The server instance is automatically
    /// managed and made available throughout the test execution scope.
    @TaskLocal
    public static var testServer: TemporalTestServer? = nil

    /// The currently active time-skipping test server instance available within test execution context.
    ///
    /// This task-local variable provides access to the time-skipping test server when
    /// using the ``TemporalTimeSkippingTestServerTrait`` test trait. Time-skipping servers
    /// accelerate temporal logic execution for efficient testing of time-dependent workflows.
    @TaskLocal
    public static var timeSkippingTestServer: TemporalTestServer? = nil

    private let serverTarget: String

    // tune the dev server for high throughput during parallel testing, otherwise running into "resource exhausted" errors
    private static let devServerOptions: BridgeTestServer.DevServerOptions = {
        var devServerOptions = BridgeTestServer.DevServerOptions.default
        devServerOptions.testServerOptions.extraArguments = """
            --dynamic-config-value=frontend.namespaceRPS=5800
            --dynamic-config-value=matching.rps=5000
            --dynamic-config-value=history.rps=7000
            """
        return devServerOptions
    }()

    /// Creates and manages a standard test server instance for the duration of the provided closure.
    ///
    /// This method starts a background Temporal server process and provides access to it
    /// through the closure parameter. The server runs with real-time execution semantics,
    /// making it suitable for functional integration testing scenarios.
    ///
    /// ## Usage
    ///
    /// ```swift
    /// try await TemporalTestServer.withTestServer { testServer in
    ///     try await testServer.withConnectedClient(logger: logger) { client in
    ///         // Perform integration tests with the client
    ///         let handle = try await client.startWorkflow(
    ///             MyWorkflow.self,
    ///             options: WorkflowOptions(id: "integration-test")
    ///         )
    ///         let result = try await handle.result()
    ///         // Validate workflow execution results
    ///     }
    /// }
    /// ```
    ///
    /// - Important: For optimal test performance and resource management, use the
    ///   ``TemporalTestServerTrait`` test trait instead of calling this method directly.
    ///   The trait ensures proper server instance sharing across related tests while
    ///   maintaining appropriate test isolation boundaries.
    ///
    /// - Parameters:
    ///   - isolation: The isolation context of the calling actor.
    ///   - body: An async closure that receives the test server instance and performs test operations.
    /// - Returns: The result value returned by the closure.
    /// - Throws: Any errors thrown by the closure or during server lifecycle management.
    public static func withTestServer<Result: Sendable>(
        isolation: isolated (any Actor)? = #isolation,
        _ body: (borrowing TemporalTestServer) async throws -> sending Result
    ) async throws -> sending Result {
        try await BridgeTestServer.withBridgeDevServer(
            devServerOptions: Self.devServerOptions,
            isolation: isolation,
        ) { bridgeTestServer, target in
            let testServer = TemporalTestServer(
                serverTarget: target
            )
            return try await body(testServer)
        }
    }

    /// Creates and manages a time-skipping test server instance for the duration of the provided closure.
    ///
    /// This method starts a background Temporal server process with time-skipping capabilities,
    /// allowing accelerated execution of time-dependent workflow logic. Time-skipping servers
    /// are ideal for testing workflows that involve timers, schedules, or other temporal behaviors
    /// without waiting for real time to pass.
    ///
    /// ## Time-skipping behavior
    ///
    /// The time-skipping server automatically advances time when workflows are waiting
    /// on timers or scheduled activities, enabling rapid testing of temporal logic:
    ///
    /// ```swift
    /// try await TemporalTestServer.withTimeSkippingTestServer { testServer in
    ///     try await testServer.withConnectedClient(logger: logger) { client in
    ///         // Test workflow with 1-hour timer completes immediately
    ///         let handle = try await client.startWorkflow(
    ///             TimerWorkflow.self,
    ///             options: WorkflowOptions(id: "timer-test")
    ///         )
    ///         let result = try await handle.result() // Completes without waiting
    ///     }
    /// }
    /// ```
    ///
    /// - Important: For optimal test performance and resource management, use the
    ///   ``TemporalTimeSkippingTestServerTrait`` test trait instead of calling this method directly.
    ///   The trait ensures proper server instance sharing across related tests while
    ///   maintaining appropriate test isolation boundaries.
    ///
    /// - Parameters:
    ///   - isolation: The isolation context of the calling actor.
    ///   - body: An async closure that receives the test server instance and performs test operations.
    /// - Throws: Any errors thrown by the closure or during server lifecycle management.
    ///
    /// - Note: This method currently has a void return type due to Swift 6.0 compiler limitations.
    ///   Future versions may support generic return types.
    public static func withTimeSkippingTestServer(
        isolation: isolated (any Actor)? = #isolation,
        _ body: (borrowing TemporalTestServer) async throws -> Void
    ) async throws {
        try await BridgeTestServer.withBridgeTestServer(isolation: isolation) { bridgeTestServer, target in
            let testServer = TemporalTestServer(
                serverTarget: target
            )
            return try await body(testServer)
        }
    }

    /// Creates a connected Temporal client for testing operations against the test server.
    ///
    /// This method establishes a client connection to the test server and provides it
    /// to the closure for performing test operations. The client is automatically
    /// configured with appropriate transport settings for the test environment.
    ///
    /// ## Usage
    ///
    /// ```swift
    /// let testServer = TemporalTestServer.testServer!
    /// try await testServer.withConnectedClient(logger: logger) { client in
    ///     // Execute workflow operations using the connected client
    ///     let handle = try await client.startWorkflow(
    ///         MyWorkflow.self,
    ///         options: WorkflowOptions(id: "test-workflow-\(UUID())")
    ///     )
    ///
    ///     // Query workflow state
    ///     let status = try await handle.query(MyWorkflow.statusQuery)
    ///
    ///     // Wait for completion and validate results
    ///     let result = try await handle.result()
    ///     XCTAssertEqual(result, expectedValue)
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - isolation: The isolation context of the calling actor.
    ///   - logger: The logger instance used by the client for diagnostic output.
    ///   - body: An async closure that receives the connected client and performs test operations.
    /// - Returns: The result value returned by the closure.
    /// - Throws: Any errors thrown during client connection establishment or by the closure.
    public func withConnectedClient<Result: Sendable>(
        isolation: isolated (any Actor)? = #isolation,
        logger: Logger,
        _ body: (TemporalClient) async throws -> sending Result
    ) async throws -> sending Result {
        try await withConnectedClient(
            isolation: isolation,
            logger: logger,
        ) { client, _, _ in
            try await body(client)
        }
    }

    /// Creates a connected Temporal client with access to server connection details for advanced testing scenarios.
    ///
    /// This method provides both a connected client and the underlying host and port
    /// information, enabling advanced testing scenarios that require direct server
    /// connection details or custom client configuration.
    ///
    /// - Parameters:
    ///   - isolation: The isolation context of the calling actor.
    ///   - logger: The logger instance used by the client for diagnostic output.
    ///   - interceptors: An array of client interceptors to apply to the connection.
    ///   - body: An async closure that receives the connected client, host, and port for test operations.
    /// - Returns: The result value returned by the closure.
    /// - Throws: Any errors thrown during client connection establishment or by the closure.
    public func withConnectedClient<Result: Sendable>(
        isolation: isolated (any Actor)? = #isolation,
        logger: Logger,
        interceptors: [any ClientInterceptor] = [],
        _ body: (TemporalClient, String, Int) async throws -> sending Result
    ) async throws -> sending Result {
        let (host, port) = self.hostAndPort()

        return try await TemporalClient.connect(
            transport: .http2NIOPosix(
                target: .dns(host: host, port: port),
                transportSecurity: .plaintext,  // plaintext transport for testing
                config: .defaults,
                resolverRegistry: .defaults,
                serviceConfig: .init(),
                eventLoopGroup: .singletonMultiThreadedEventLoopGroup
            ),
            configuration: .init(
                instrumentation: .init(serverHostname: host),
                interceptors: interceptors
            ),
            isolation: isolation,
            logger: logger,
        ) { client in
            try await body(client, host, port)
        }
    }

    /// Creates a connected Temporal worker for test scenarios, then executes your closure against it.
    ///
    /// This helper spins up a `TemporalWorker` using an in-process,
    /// plaintext transport to the test server. The worker runs concurrently while your `body` closure
    /// executes; once the closure finishes (or throws), the worker task is cancelled and torn down.
    ///
    /// The worker can be customized with namespace, task queue, interceptors, activities, workflows,
    /// logging, and heartbeat throttling. By default, a fresh random task queue is used so tests
    /// remain isolated.
    ///
    /// ## Usage
    ///
    /// ```swift
    /// let testServer = TemporalTestServer.testServer!
    /// let result = try await testServer.withConnectedWorker(
    ///     namespace: "default",
    ///     activities: [MyActivity()],
    ///     workflows: [MyWorkflow.self]
    /// ) { worker in
    ///     // Interact with the system under test while the worker is running.
    ///     // For example, start a workflow from a connected client (e.g. via `withConnectedClient()`),
    ///     // then await its result.
    /// }
    ///
    /// #expect(result == "...")
    /// ```
    ///
    /// - Parameters:
    ///   - namespace: Temporal namespace to register the worker with. Defaults to `"default"`.
    ///   - taskQueue: Task queue the worker will poll. Defaults to a fresh random UUID to avoid collisions between tests.
    ///   - workerBuildID: Optional Build ID for worker versioning. (Defaults to an empty string.)
    ///   - maxHeartbeatThrottleInterval: Maximum server-side heartbeat throttle interval used by the worker. Defaults to 60 seconds.
    ///   - interceptors: Worker interceptors to install for testing/tracing.
    ///   - activities: Activity implementations to register on the worker.
    ///   - workflows: Workflow types to register on the worker.
    ///   - logger: Logger used by the worker. Defaults to a stdout `Logger` at `.info`.
    ///   - isolation: The isolation context of the calling actor. Defaults to `#isolation`.
    ///   - body: An async closure that receives the running worker and performs test operations. When the closure completes, the worker is cancelled.
    /// - Returns: The value returned by `body`.
    /// - Throws: Any error thrown while creating/starting the worker, establishing the transport, or by the `body` closure.
    /// - Note: The worker is run concurrently in a `TaskGroup`. The group is cancelled after the first task
    ///   (typically your `body`) completes. The transport uses plaintext HTTP/2 and is intended for test environments only.
    public func withConnectedWorker<Result: Sendable>(
        namespace: String = "default",
        taskQueue: String = UUID().uuidString,
        workerBuildID: String = "",
        maxHeartbeatThrottleInterval: Duration = .seconds(60),
        interceptors: [any WorkerInterceptor] = [],
        activities: [any ActivityDefinition] = [],
        workflows: [any WorkflowDefinition.Type] = [],
        logger: Logger = {
            var logger = Logger(label: "TestWorker", factory: { StreamLogHandler.standardOutput(label: $0) })
            logger.logLevel = .info
            return logger
        }(),
        isolation: isolated (any Actor)? = #isolation,
        _ body: sending @escaping @isolated(any) (TemporalWorker) async throws -> sending Result
    ) async throws -> sending Result {
        try await self.withConnectedWorker(
            namespace: namespace,
            taskQueue: taskQueue,
            workerBuildID: workerBuildID,
            maxHeartbeatThrottleInterval: maxHeartbeatThrottleInterval,
            interceptors: interceptors,
            activities: activities,
            workflows: workflows,
            workerType: TemporalWorker.self,
            logger: logger
        ) { worker in
            try await body(worker)
        }
    }

    /// Creates a connected Temporal worker for test scenarios including a specific worker type.
    package func withConnectedWorker<Result: Sendable, Worker: TemporalWorkerProtocol>(
        namespace: String = "default",
        taskQueue: String = UUID().uuidString,
        workerBuildID: String = "",
        maxHeartbeatThrottleInterval: Duration = .seconds(60),
        interceptors: [any WorkerInterceptor] = [],
        activities: [any ActivityDefinition] = [],
        workflows: [any WorkflowDefinition.Type] = [],
        workerType: Worker.Type = Worker.self,
        logger: Logger = {
            var logger = Logger(label: "TestWorker", factory: { StreamLogHandler.standardOutput(label: $0) })
            logger.logLevel = .info
            return logger
        }(),
        isolation: isolated (any Actor)? = #isolation,
        _ body: sending @escaping @isolated(any) (Worker) async throws -> sending Result
    ) async throws -> sending Result {
        try await withThrowingTaskGroup(of: Result?.self) { group in
            nonisolated(unsafe) let body = body

            let (host, port) = self.hostAndPort()

            var workerConfiguration = TemporalWorker.Configuration(
                namespace: namespace,
                taskQueue: taskQueue,
                instrumentation: .init(serverHostname: host),
                clientIdentity: nil,  // defaults to the SDK name and version followed by a unique ID
                dataConverter: .default
            )
            workerConfiguration.interceptors = interceptors
            workerConfiguration.maxHeartbeatThrottleInterval = maxHeartbeatThrottleInterval

            let worker = Worker(
                for: workerConfiguration,
                transport: try .http2NIOPosix(
                    target: .dns(host: host, port: port),
                    transportSecurity: .plaintext,  // plaintext transport for testing
                    config: .defaults,
                    resolverRegistry: .defaults,
                    serviceConfig: .init()
                ),
                activities: activities,
                workflows: workflows,
                logger: logger
            )

            group.addTask {
                try await worker.run(bridgeRuntime: BridgeTestServer.bridgeRuntime)  // pass in the single runtime we have for testing
                return nil
            }

            group.addTask { @Sendable in
                try await body(worker)
            }

            let result = await group.nextResult()!
            group.cancelAll()
            return try result.get()!
        }
    }

    /// Provides the host and port information from the server target address.
    ///
    /// - Returns: A tuple containing the host string and port number for the test server.
    public func hostAndPort() -> (host: String, port: Int) {
        let parts = self.serverTarget.split(separator: ":", maxSplits: 1, omittingEmptySubsequences: false)

        guard let host = parts.first.map(String.init),
            parts.count > 1,
            let port = Int(parts[1])
        else {
            fatalError("Invalid host and port received from test server.")
        }

        return (host: host, port: port)
    }
}

/// Test trait providing managed standard test server instances for integration testing scenarios.
///
/// ``TemporalTestServerTrait`` is a Swift Testing trait that automatically manages
/// the lifecycle of a standard Temporal test server for your test suite. The trait
/// ensures that a single test server instance is shared across all tests in the
/// suite while maintaining proper isolation between different test suites.
///
/// ## Usage
///
/// Apply this trait to test suites that require integration testing with a real
/// Temporal server instance:
///
/// ```swift
/// @Test(.temporalTestServer)
/// struct WorkflowIntegrationTests {
///     @Test
///     func testWorkflowExecution() async throws {
///         let testServer = TemporalTestServer.testServer!
///         try await testServer.withConnectedClient(logger: logger) { client in
///             // Perform integration tests
///         }
///     }
///
///     @Test
///     func testActivityExecution() async throws {
///         let testServer = TemporalTestServer.testServer!
///         // Access the same server instance across tests
///     }
/// }
/// ```
public struct TemporalTestServerTrait: SuiteTrait, TestTrait, TestScoping {
    public func provideScope(
        for test: Test,
        testCase: Test.Case?,
        performing function: @Sendable () async throws -> Void
    ) async throws {
        try await TemporalTestServer.withTestServer { testServer in
            try await TemporalTestServer.$testServer.withValue(testServer) {
                try await function()
            }
        }
    }
}

/// Test trait providing managed time-skipping test server instances for temporal logic testing scenarios.
///
/// ``TemporalTimeSkippingTestServerTrait`` is a Swift Testing trait that automatically
/// manages the lifecycle of a time-skipping Temporal test server for your test suite.
/// Time-skipping servers accelerate temporal execution, making them ideal for testing
/// workflows with timers, schedules, and other time-dependent behaviors.
///
/// ## Usage
///
/// Apply this trait to test suites that need to test time-dependent workflow logic:
///
/// ```swift
/// @Test(.temporalTimeSkippingTestServer)
/// struct TimerBasedWorkflowTests {
///     @Test
///     func testScheduledWorkflow() async throws {
///         let testServer = TemporalTestServer.timeSkippingTestServer!
///         try await testServer.withConnectedClient(logger: logger) { client in
///             // Test workflows with timers - time advances automatically
///             let handle = try await client.startWorkflow(
///                 ScheduledWorkflow.self,
///                 options: WorkflowOptions(id: "timer-test")
///             )
///             // Timer-based logic executes immediately
///             let result = try await handle.result()
///         }
///     }
/// }
/// ```
public struct TemporalTimeSkippingTestServerTrait: SuiteTrait, TestTrait, TestScoping {
    public func provideScope(
        for test: Test,
        testCase: Test.Case?,
        performing function: @Sendable () async throws -> Void
    ) async throws {
        try await TemporalTestServer.withTimeSkippingTestServer { testServer in
            try await TemporalTestServer.$timeSkippingTestServer.withValue(testServer) {
                try await function()
            }
        }
    }
}

extension Trait where Self == TemporalTestServerTrait {
    /// A test trait that provides managed standard test server instances for integration testing.
    public static var temporalTestServer: Self {
        Self()
    }
}

extension Trait where Self == TemporalTimeSkippingTestServerTrait {
    /// A test trait that provides managed time-skipping test server instances for temporal logic testing.
    public static var temporalTimeSkippingTestServer: Self {
        Self()
    }
}
#endif
