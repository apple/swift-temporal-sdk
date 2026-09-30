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

import Synchronization
import Temporal
import Testing

private struct LifecycleTestError: Error, Equatable {
    let tag: String
}

// MARK: - Client lifecycle hook

@Suite(.tags(.pluginTests))
struct ClientLifecycleHookTests {
    private struct DefaultPlugin: ClientPlugin {}

    /// A `ClientPlugin` whose `connectClient(configuration:next:)` records a before- and after-marker
    /// around `next()`.
    ///
    /// Tests use this to observe wrap order and error propagation without needing a real transport.
    private struct RecordingClientPlugin: ClientPlugin {
        let onBefore: @Sendable () -> Void
        let onAfter: @Sendable () -> Void

        func connectClient<R: Sendable>(
            configuration: TemporalClient.Configuration,
            next: () async throws -> sending R
        ) async throws -> sending R {
            onBefore()
            let result = try await next()
            onAfter()
            return result
        }
    }

    private static func makeConfiguration() -> TemporalClient.Configuration {
        TemporalClient.Configuration(instrumentation: .init(serverHostname: "localhost"))
    }

    @Test
    func defaultConnectClientForwardsThroughToNext() async throws {
        let result = try await DefaultPlugin().connectClient(
            configuration: Self.makeConfiguration()
        ) {
            "next-value"
        }
        #expect(result == "next-value")
    }

    @Test
    func customConnectClientRunsBeforeAndAfterNext() async throws {
        let log = Mutex<[String]>([])
        let plugin = RecordingClientPlugin(
            onBefore: { log.withLock { $0.append("before") } },
            onAfter: { log.withLock { $0.append("after") } }
        )

        let result: Int = try await plugin.connectClient(configuration: Self.makeConfiguration()) {
            log.withLock { $0.append("body") }
            return 42
        }

        #expect(result == 42)
        #expect(log.withLock { $0 } == ["before", "body", "after"])
    }

    @Test
    func connectChainComposesInArrayOrder() async throws {
        // The first plugin in the array must be the outermost wrap, the last innermost.
        let log = Mutex<[String]>([])
        func make(_ name: String) -> RecordingClientPlugin {
            RecordingClientPlugin(
                onBefore: { log.withLock { $0.append("\(name).before") } },
                onAfter: { log.withLock { $0.append("\(name).after") } }
            )
        }
        let plugins: [any ClientPlugin] = [make("A"), make("B")]

        let result: String = try await applyClientConnectChain(
            plugins: plugins[...],
            configuration: Self.makeConfiguration()
        ) {
            log.withLock { $0.append("body") }
            return "ok"
        }

        #expect(result == "ok")
        #expect(log.withLock { $0 } == ["A.before", "B.before", "body", "B.after", "A.after"])
    }

    @Test
    func connectChainPropagatesBodyError() async throws {
        // When the body throws, plugins that already ran their "before" do not run their "after",
        // and the error reaches the caller unchanged.
        let log = Mutex<[String]>([])
        func make(_ name: String) -> RecordingClientPlugin {
            RecordingClientPlugin(
                onBefore: { log.withLock { $0.append("\(name).before") } },
                onAfter: { log.withLock { $0.append("\(name).after") } }
            )
        }
        let plugins: [any ClientPlugin] = [make("A"), make("B")]

        await #expect(throws: LifecycleTestError(tag: "boom")) {
            let _: String = try await applyClientConnectChain(
                plugins: plugins[...],
                configuration: Self.makeConfiguration()
            ) {
                throw LifecycleTestError(tag: "boom")
            }
        }

        #expect(log.withLock { $0 } == ["A.before", "B.before"])
    }

    @Test
    func emptyPluginChainCallsBodyDirectly() async throws {
        let configuration = Self.makeConfiguration()
        let result: Int = try await applyClientConnectChain(
            plugins: ArraySlice<any ClientPlugin>([]),
            configuration: configuration
        ) {
            7
        }
        #expect(result == 7)
    }
}

// MARK: - Worker lifecycle hook

@Suite(.tags(.pluginTests))
struct WorkerLifecycleHookTests {
    private struct DefaultPlugin: WorkerPlugin {}

    /// A `WorkerPlugin` whose `runWorker(configuration:next:)` records a before- and after-marker
    /// around `next()`.
    private struct RecordingWorkerPlugin: WorkerPlugin {
        let onBefore: @Sendable () -> Void
        let onAfter: @Sendable () -> Void

        func runWorker(
            configuration: TemporalWorker.Configuration,
            next: () async throws -> Void
        ) async throws {
            onBefore()
            try await next()
            onAfter()
        }
    }

    private static func makeConfiguration() -> TemporalWorker.Configuration {
        TemporalWorker.Configuration(
            namespace: "test",
            taskQueue: "test-queue",
            instrumentation: .init(serverHostname: "localhost")
        )
    }

    @Test
    func defaultRunWorkerForwardsThroughToNext() async throws {
        let ran = Mutex<Bool>(false)
        try await DefaultPlugin().runWorker(configuration: Self.makeConfiguration()) {
            ran.withLock { $0 = true }
        }
        #expect(ran.withLock { $0 } == true)
    }

    @Test
    func customRunWorkerRunsBeforeAndAfterNext() async throws {
        let log = Mutex<[String]>([])
        let plugin = RecordingWorkerPlugin(
            onBefore: { log.withLock { $0.append("before") } },
            onAfter: { log.withLock { $0.append("after") } }
        )

        try await plugin.runWorker(configuration: Self.makeConfiguration()) {
            log.withLock { $0.append("body") }
        }

        #expect(log.withLock { $0 } == ["before", "body", "after"])
    }

    @Test
    func runWorkerChainComposesInArrayOrder() async throws {
        let log = Mutex<[String]>([])
        func make(_ name: String) -> RecordingWorkerPlugin {
            RecordingWorkerPlugin(
                onBefore: { log.withLock { $0.append("\(name).before") } },
                onAfter: { log.withLock { $0.append("\(name).after") } }
            )
        }
        let plugins: [any WorkerPlugin] = [make("A"), make("B")]

        try await applyWorkerRunChain(
            plugins: plugins[...],
            configuration: Self.makeConfiguration()
        ) {
            log.withLock { $0.append("body") }
        }

        #expect(log.withLock { $0 } == ["A.before", "B.before", "body", "B.after", "A.after"])
    }

    @Test
    func runWorkerChainPropagatesBodyError() async throws {
        let log = Mutex<[String]>([])
        func make(_ name: String) -> RecordingWorkerPlugin {
            RecordingWorkerPlugin(
                onBefore: { log.withLock { $0.append("\(name).before") } },
                onAfter: { log.withLock { $0.append("\(name).after") } }
            )
        }
        let plugins: [any WorkerPlugin] = [make("A"), make("B")]

        await #expect(throws: LifecycleTestError(tag: "boom")) {
            try await applyWorkerRunChain(
                plugins: plugins[...],
                configuration: Self.makeConfiguration()
            ) {
                throw LifecycleTestError(tag: "boom")
            }
        }

        #expect(log.withLock { $0 } == ["A.before", "B.before"])
    }
}

// MARK: - Replayer lifecycle hook

@Suite(.tags(.pluginTests))
struct ReplayerLifecycleHookTests {
    private struct DefaultPlugin: WorkerPlugin {}

    /// A `WorkerPlugin` whose `runReplayer(configuration:next:)` records a before- and after-marker
    /// around `next()`.
    private struct RecordingReplayerPlugin: WorkerPlugin {
        let onBefore: @Sendable () -> Void
        let onAfter: @Sendable () -> Void

        func runReplayer<R: Sendable>(
            configuration: WorkflowReplayer.Configuration,
            next: () async throws -> sending R
        ) async throws -> sending R {
            onBefore()
            let result = try await next()
            onAfter()
            return result
        }
    }

    @Test
    func defaultRunReplayerForwardsThroughToNext() async throws {
        let result = try await DefaultPlugin().runReplayer(
            configuration: WorkflowReplayer.Configuration()
        ) {
            "next-value"
        }
        #expect(result == "next-value")
    }

    @Test
    func customRunReplayerRunsBeforeAndAfterNext() async throws {
        let log = Mutex<[String]>([])
        let plugin = RecordingReplayerPlugin(
            onBefore: { log.withLock { $0.append("before") } },
            onAfter: { log.withLock { $0.append("after") } }
        )

        let result: Int = try await plugin.runReplayer(configuration: WorkflowReplayer.Configuration()) {
            log.withLock { $0.append("body") }
            return 99
        }

        #expect(result == 99)
        #expect(log.withLock { $0 } == ["before", "body", "after"])
    }

    @Test
    func runReplayerChainComposesInArrayOrder() async throws {
        let log = Mutex<[String]>([])
        func make(_ name: String) -> RecordingReplayerPlugin {
            RecordingReplayerPlugin(
                onBefore: { log.withLock { $0.append("\(name).before") } },
                onAfter: { log.withLock { $0.append("\(name).after") } }
            )
        }
        let plugins: [any WorkerPlugin] = [make("A"), make("B")]

        let result: String = try await applyReplayerRunChain(
            plugins: plugins[...],
            configuration: WorkflowReplayer.Configuration()
        ) {
            log.withLock { $0.append("body") }
            return "ok"
        }

        #expect(result == "ok")
        #expect(log.withLock { $0 } == ["A.before", "B.before", "body", "B.after", "A.after"])
    }

    @Test
    func runReplayerChainPropagatesBodyError() async throws {
        let log = Mutex<[String]>([])
        func make(_ name: String) -> RecordingReplayerPlugin {
            RecordingReplayerPlugin(
                onBefore: { log.withLock { $0.append("\(name).before") } },
                onAfter: { log.withLock { $0.append("\(name).after") } }
            )
        }
        let plugins: [any WorkerPlugin] = [make("A"), make("B")]

        await #expect(throws: LifecycleTestError(tag: "boom")) {
            let _: String = try await applyReplayerRunChain(
                plugins: plugins[...],
                configuration: WorkflowReplayer.Configuration()
            ) {
                throw LifecycleTestError(tag: "boom")
            }
        }

        #expect(log.withLock { $0 } == ["A.before", "B.before"])
    }
}
