//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Temporal SDK open source project
//
// Copyright (c) 2026 Apple Inc. and the Swift Temporal SDK project authors
// Licensed under MIT License
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Swift Temporal SDK project authors
//
// SPDX-License-Identifier: MIT
//
//===----------------------------------------------------------------------===//

private import Logging
import SwiftProtobuf
import Synchronization
import Temporal
import Testing

private let testLogger = Logger(label: "test")

private struct SimplePluginTestError: Error, Equatable {
    let tag: String
}

struct MarkerPayloadCodec: PayloadCodec {
    func encode(payloads: some Collection<Api.Common.V1.Payload>) async throws -> [Api.Common.V1.Payload] {
        Array(payloads)
    }
    func decode(payloads: some Collection<Api.Common.V1.Payload>) async throws -> [Api.Common.V1.Payload] {
        Array(payloads)
    }
}

@Suite(.tags(.pluginTests))
struct SimplePluginTests {
    @Workflow
    struct PingWorkflow {
        mutating func run(context: WorkflowContext<Self>, input: Void) async throws {}
    }

    @Workflow
    struct ConfiguredWorkflow {
        mutating func run(context: WorkflowContext<Self>, input: Void) async throws {}
    }

    /// Installs ``MarkerPayloadCodec`` on whatever it configures.
    private static let markerCodecPlugin = SimplePlugin(
        name: "marker",
        dataConverter: { existing in
            DataConverter(
                payloadConverter: existing.payloadConverter,
                failureConverter: existing.failureConverter,
                payloadCodec: MarkerPayloadCodec()
            )
        }
    )

    // MARK: Client side

    @Test
    func clientInterceptorsAreAppended() {
        var configuration = TemporalClient.Configuration(
            instrumentation: .init(serverHostname: "localhost")
        )
        let initialCount = configuration.interceptors.count

        let plugin = SimplePlugin(
            name: "test",
            clientInterceptors: [TemporalClientTracingInterceptor()]
        )
        plugin.configureClient(&configuration)

        #expect(configuration.interceptors.count == initialCount + 1)
        #expect(configuration.interceptors.last is TemporalClientTracingInterceptor)
    }

    @Test
    func clientDataConverterClosureRunsWithExistingConverter() {
        var configuration = TemporalClient.Configuration(
            instrumentation: .init(serverHostname: "localhost")
        )
        let captured = Mutex<DataConverter?>(nil)

        let plugin = SimplePlugin(
            name: "test",
            dataConverter: { existing in
                captured.withLock { $0 = existing }
                return DataConverter(
                    payloadConverter: existing.payloadConverter,
                    failureConverter: existing.failureConverter,
                    payloadCodec: MarkerPayloadCodec()
                )
            }
        )
        plugin.configureClient(&configuration)

        #expect(captured.withLock { $0 != nil })
        #expect(configuration.dataConverter.payloadCodec is MarkerPayloadCodec)
    }

    @Test
    func clientDataConvertersComposeInArrayOrder() {
        // Two SimplePlugin instances each wrap the existing data converter. Asserting the call
        // order alone would not show composition, so the first installs MarkerPayloadCodec and the
        // second records whether it received that converter rather than the original.
        let chain = Mutex<[String]>([])
        let secondSawMarkerCodec = Mutex<Bool?>(nil)

        let first = SimplePlugin(
            name: "first",
            dataConverter: { existing in
                chain.withLock { $0.append("first") }
                return DataConverter(
                    payloadConverter: existing.payloadConverter,
                    failureConverter: existing.failureConverter,
                    payloadCodec: MarkerPayloadCodec()
                )
            }
        )
        let second = SimplePlugin(
            name: "second",
            dataConverter: { existing in
                chain.withLock { $0.append("second") }
                secondSawMarkerCodec.withLock { $0 = existing.payloadCodec is MarkerPayloadCodec }
                return existing
            }
        )

        var configuration = TemporalClient.Configuration(
            instrumentation: .init(serverHostname: "localhost"),
            plugins: [first, second]
        )

        configuration.applyPlugins(logger: testLogger)

        #expect(chain.withLock { $0 } == ["first", "second"])
        #expect(secondSawMarkerCodec.withLock { $0 } == true)
        #expect(configuration.dataConverter.payloadCodec is MarkerPayloadCodec)
    }

    // MARK: Worker side

    @Test
    func workerInterceptorsAreAppended() {
        var configuration = TemporalWorker.Configuration(
            namespace: "test",
            taskQueue: "test-queue",
            instrumentation: .init(serverHostname: "localhost")
        )
        let initialCount = configuration.interceptors.count

        let plugin = SimplePlugin(
            name: "test",
            workerInterceptors: [TemporalWorkerTracingInterceptor()]
        )
        plugin.configureWorker(&configuration)

        #expect(configuration.interceptors.count == initialCount + 1)
        #expect(configuration.interceptors.last is TemporalWorkerTracingInterceptor)
    }

    @Test
    func workerDataConverterIsTransformed() {
        var configuration = TemporalWorker.Configuration(
            namespace: "test",
            taskQueue: "test-queue",
            instrumentation: .init(serverHostname: "localhost")
        )

        Self.markerCodecPlugin.configureWorker(&configuration)

        #expect(configuration.dataConverter.payloadCodec is MarkerPayloadCodec)
    }

    // MARK: Replayer

    @Test
    func replayerInterceptorsAreAppended() {
        var configuration = WorkflowReplayer.Configuration()
        let initialCount = configuration.interceptors.count

        let plugin = SimplePlugin(
            name: "test",
            workerInterceptors: [TemporalWorkerTracingInterceptor()]
        )
        plugin.configureReplayer(&configuration)

        #expect(configuration.interceptors.count == initialCount + 1)
        #expect(configuration.interceptors.last is TemporalWorkerTracingInterceptor)
    }

    @Test
    func replayerDataConverterIsTransformed() {
        var configuration = WorkflowReplayer.Configuration()

        Self.markerCodecPlugin.configureReplayer(&configuration)

        #expect(configuration.dataConverter.payloadCodec is MarkerPayloadCodec)
    }

    @Test
    func replayerApplyAppendsSimplePluginWorkflows() {
        // `WorkflowReplayer` keeps its configuration private, so this calls `applyPlugins()`
        // directly to assert on `configuration.workflows` without replaying a history.
        let plugin = SimplePlugin(name: "test", workflows: [PingWorkflow.self])
        var configuration = WorkflowReplayer.Configuration(
            workflows: [ConfiguredWorkflow.self],
            plugins: [plugin]
        )

        configuration.applyPlugins()

        #expect(configuration.workflows.count == 2)
        #expect(configuration.workflows.first == ConfiguredWorkflow.self)
        #expect(configuration.workflows.last == PingWorkflow.self)
    }

    // MARK: Lifecycle wraps

    @Test
    func connectClientWithoutClosuresForwardsThroughToNext() async throws {
        let plugin = SimplePlugin(name: "test")
        let result = try await plugin.connectClient(
            configuration: TemporalClient.Configuration(
                instrumentation: .init(serverHostname: "localhost")
            )
        ) {
            "next-value"
        }
        #expect(result == "next-value")
    }

    @Test
    func connectClientClosuresRunAroundNext() async throws {
        let log = Mutex<[String]>([])
        let plugin = SimplePlugin(
            name: "test",
            beforeConnect: { _ in log.withLock { $0.append("before") } },
            afterConnect: { _ in log.withLock { $0.append("after") } }
        )

        let result: Int = try await plugin.connectClient(
            configuration: TemporalClient.Configuration(
                instrumentation: .init(serverHostname: "localhost")
            )
        ) {
            log.withLock { $0.append("body") }
            return 42
        }

        #expect(result == 42)
        #expect(log.withLock { $0 } == ["before", "body", "after"])
    }

    @Test
    func runWorkerWithoutClosuresForwardsThroughToNext() async throws {
        let plugin = SimplePlugin(name: "test")
        let ran = Mutex<Bool>(false)
        try await plugin.runWorker(
            configuration: TemporalWorker.Configuration(
                namespace: "test",
                taskQueue: "test-queue",
                instrumentation: .init(serverHostname: "localhost")
            )
        ) {
            ran.withLock { $0 = true }
        }
        #expect(ran.withLock { $0 } == true)
    }

    @Test
    func runWorkerClosuresRunAroundNext() async throws {
        let log = Mutex<[String]>([])
        let plugin = SimplePlugin(
            name: "test",
            beforeRunWorker: { _ in log.withLock { $0.append("before") } },
            afterRunWorker: { _ in log.withLock { $0.append("after") } }
        )

        try await plugin.runWorker(
            configuration: TemporalWorker.Configuration(
                namespace: "test",
                taskQueue: "test-queue",
                instrumentation: .init(serverHostname: "localhost")
            )
        ) {
            log.withLock { $0.append("body") }
        }

        #expect(log.withLock { $0 } == ["before", "body", "after"])
    }

    @Test
    func runReplayerWithoutClosuresForwardsThroughToNext() async throws {
        let plugin = SimplePlugin(name: "test")
        let result = try await plugin.runReplayer(
            configuration: WorkflowReplayer.Configuration()
        ) {
            "next-value"
        }
        #expect(result == "next-value")
    }

    @Test
    func runReplayerClosuresRunAroundNext() async throws {
        let log = Mutex<[String]>([])
        let plugin = SimplePlugin(
            name: "test",
            beforeRunReplayer: { _ in log.withLock { $0.append("before") } },
            afterRunReplayer: { _ in log.withLock { $0.append("after") } }
        )

        let result: Int = try await plugin.runReplayer(
            configuration: WorkflowReplayer.Configuration()
        ) {
            log.withLock { $0.append("body") }
            return 99
        }

        #expect(result == 99)
        #expect(log.withLock { $0 } == ["before", "body", "after"])
    }

    // MARK: Lifecycle wraps, error paths

    @Test
    func afterConnectRunsWhenInnerWorkThrows() async throws {
        let log = Mutex<[String]>([])
        let plugin = SimplePlugin(
            name: "test",
            beforeConnect: { _ in log.withLock { $0.append("before") } },
            afterConnect: { _ in log.withLock { $0.append("after") } }
        )

        await #expect(throws: SimplePluginTestError(tag: "boom")) {
            let _: String = try await plugin.connectClient(
                configuration: TemporalClient.Configuration(
                    instrumentation: .init(serverHostname: "localhost")
                )
            ) {
                log.withLock { $0.append("body") }
                throw SimplePluginTestError(tag: "boom")
            }
        }

        #expect(log.withLock { $0 } == ["before", "body", "after"])
    }

    @Test
    func afterRunWorkerRunsWhenInnerWorkThrows() async throws {
        let log = Mutex<[String]>([])
        let plugin = SimplePlugin(
            name: "test",
            beforeRunWorker: { _ in log.withLock { $0.append("before") } },
            afterRunWorker: { _ in log.withLock { $0.append("after") } }
        )

        await #expect(throws: SimplePluginTestError(tag: "boom")) {
            try await plugin.runWorker(
                configuration: TemporalWorker.Configuration(
                    namespace: "test",
                    taskQueue: "test-queue",
                    instrumentation: .init(serverHostname: "localhost")
                )
            ) {
                log.withLock { $0.append("body") }
                throw SimplePluginTestError(tag: "boom")
            }
        }

        #expect(log.withLock { $0 } == ["before", "body", "after"])
    }

    @Test
    func afterRunReplayerRunsWhenInnerWorkThrows() async throws {
        let log = Mutex<[String]>([])
        let plugin = SimplePlugin(
            name: "test",
            beforeRunReplayer: { _ in log.withLock { $0.append("before") } },
            afterRunReplayer: { _ in log.withLock { $0.append("after") } }
        )

        await #expect(throws: SimplePluginTestError(tag: "boom")) {
            let _: String = try await plugin.runReplayer(
                configuration: WorkflowReplayer.Configuration()
            ) {
                log.withLock { $0.append("body") }
                throw SimplePluginTestError(tag: "boom")
            }
        }

        #expect(log.withLock { $0 } == ["before", "body", "after"])
    }

    @Test
    func workErrorWinsOverAfterClosureError() async throws {
        let afterCalls = Mutex(0)
        let plugin = SimplePlugin(
            name: "test",
            afterConnect: { _ in
                afterCalls.withLock { $0 += 1 }
                throw SimplePluginTestError(tag: "from-after")
            }
        )

        await #expect(throws: SimplePluginTestError(tag: "from-body")) {
            let _: String = try await plugin.connectClient(
                configuration: TemporalClient.Configuration(
                    instrumentation: .init(serverHostname: "localhost")
                )
            ) {
                throw SimplePluginTestError(tag: "from-body")
            }
        }

        #expect(afterCalls.withLock { $0 } == 1)
    }

    @Test
    func afterClosuresThatThrowAfterSuccessRunOnceAndPropagate() async throws {
        let afterCalls = Mutex(0)
        let after: @Sendable () throws -> Void = {
            afterCalls.withLock { $0 += 1 }
            throw SimplePluginTestError(tag: "from-after")
        }
        let plugin = SimplePlugin(
            name: "test",
            afterConnect: { _ in try after() },
            afterRunWorker: { _ in try after() },
            afterRunReplayer: { _ in try after() }
        )

        await #expect(throws: SimplePluginTestError(tag: "from-after")) {
            let _: String = try await plugin.connectClient(
                configuration: TemporalClient.Configuration(instrumentation: .init(serverHostname: "localhost"))
            ) { "ok" }
        }
        await #expect(throws: SimplePluginTestError(tag: "from-after")) {
            try await plugin.runWorker(
                configuration: TemporalWorker.Configuration(
                    namespace: "test",
                    taskQueue: "test-queue",
                    instrumentation: .init(serverHostname: "localhost")
                )
            ) {}
        }
        await #expect(throws: SimplePluginTestError(tag: "from-after")) {
            let _: String = try await plugin.runReplayer(configuration: WorkflowReplayer.Configuration()) { "ok" }
        }

        #expect(afterCalls.withLock { $0 } == 3)
    }

    @Test
    func afterClosureErrorWinsOverCancellationError() async throws {
        // A worker's run normally ends with a CancellationError, so a failed teardown must not be hidden by it.
        let plugin = SimplePlugin(
            name: "test",
            afterRunWorker: { _ in throw SimplePluginTestError(tag: "from-after") }
        )

        await #expect(throws: SimplePluginTestError(tag: "from-after")) {
            try await plugin.runWorker(
                configuration: TemporalWorker.Configuration(
                    namespace: "test",
                    taskQueue: "test-queue",
                    instrumentation: .init(serverHostname: "localhost")
                )
            ) {
                throw CancellationError()
            }
        }
    }

    @Test
    func cancellationErrorPropagatesWhenAfterClosureSucceeds() async throws {
        let afterCalls = Mutex(0)
        let plugin = SimplePlugin(
            name: "test",
            afterRunWorker: { _ in afterCalls.withLock { $0 += 1 } }
        )

        await #expect(throws: CancellationError.self) {
            try await plugin.runWorker(
                configuration: TemporalWorker.Configuration(
                    namespace: "test",
                    taskQueue: "test-queue",
                    instrumentation: .init(serverHostname: "localhost")
                )
            ) {
                throw CancellationError()
            }
        }

        #expect(afterCalls.withLock { $0 } == 1)
    }

    @Test
    func beforeClosureErrorSkipsInnerWorkAndAfterClosure() async throws {
        let log = Mutex<[String]>([])
        let plugin = SimplePlugin(
            name: "test",
            beforeConnect: { _ in throw SimplePluginTestError(tag: "from-before") },
            afterConnect: { _ in log.withLock { $0.append("after") } }
        )

        await #expect(throws: SimplePluginTestError(tag: "from-before")) {
            let _: String = try await plugin.connectClient(
                configuration: TemporalClient.Configuration(
                    instrumentation: .init(serverHostname: "localhost")
                )
            ) {
                log.withLock { $0.append("body") }
                return "ok"
            }
        }

        #expect(log.withLock { $0 }.isEmpty)
    }
}
