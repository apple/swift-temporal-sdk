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
import Synchronization
import Temporal
import Testing

private let testLogger = Logger(label: "test")

@Suite(.tags(.pluginTests))
struct WorkerPluginTests {
    /// Sentinel WorkerInterceptor used to verify type identity of the appended interceptor.
    ///
    /// `WorkerInterceptor` provides defaults for all requirements, so the conformance is empty.
    private struct SentinelWorkerInterceptor: WorkerInterceptor {}

    private struct TaskQueueStampPlugin: WorkerPlugin {
        let stamp: String
        func configureWorker(_ configuration: inout TemporalWorker.Configuration) {
            configuration.taskQueue = stamp
        }
    }

    private struct AppendInterceptorPlugin: WorkerPlugin {
        func configureWorker(_ configuration: inout TemporalWorker.Configuration) {
            configuration.interceptors.append(SentinelWorkerInterceptor())
        }

        func configureReplayer(_ configuration: inout WorkflowReplayer.Configuration) {
            configuration.interceptors.append(SentinelWorkerInterceptor())
        }
    }

    /// Invokes `onConfigure` when its ``configureWorker(_:)`` runs.
    private struct CallbackPlugin: WorkerPlugin {
        let onConfigure: @Sendable (inout TemporalWorker.Configuration) -> Void
        func configureWorker(_ configuration: inout TemporalWorker.Configuration) {
            onConfigure(&configuration)
        }
    }

    /// Appends another plugin to the configuration's `plugins` from inside its own
    /// ``configureWorker(_:)`` and ``configureReplayer(_:)``.
    private struct AppendingPlugin: WorkerPlugin {
        let appended: any WorkerPlugin
        func configureWorker(_ configuration: inout TemporalWorker.Configuration) {
            configuration.plugins.append(appended)
        }

        func configureReplayer(_ configuration: inout WorkflowReplayer.Configuration) {
            configuration.plugins.append(appended)
        }
    }

    private static func makeConfiguration(plugins: [any WorkerPlugin]) -> TemporalWorker.Configuration {
        TemporalWorker.Configuration(
            namespace: "test",
            taskQueue: "test-queue",
            instrumentation: .init(serverHostname: "localhost"),
            plugins: plugins
        )
    }

    @Test
    func pluginsRunInArrayOrderOnApply() {
        var configuration = Self.makeConfiguration(plugins: [
            TaskQueueStampPlugin(stamp: "first"),
            TaskQueueStampPlugin(stamp: "second"),
        ])

        configuration.applyPlugins(logger: testLogger)

        #expect(configuration.taskQueue == "second")
    }

    @Test
    func pluginAppendsWorkerInterceptorOnApply() {
        var configuration = Self.makeConfiguration(plugins: [AppendInterceptorPlugin()])
        let initialCount = configuration.interceptors.count

        configuration.applyPlugins(logger: testLogger)

        #expect(configuration.interceptors.count == initialCount + 1)
        #expect(configuration.interceptors.last is SentinelWorkerInterceptor)
    }

    @Test
    func laterPluginObservesEarlierPluginMutations() {
        // The second plugin must see the interceptor the first one appended.
        let observedCount = Mutex<Int?>(nil)
        var configuration = Self.makeConfiguration(plugins: [
            AppendInterceptorPlugin(),
            CallbackPlugin { configuration in
                observedCount.withLock { $0 = configuration.interceptors.count }
            },
        ])
        let initialCount = configuration.interceptors.count

        configuration.applyPlugins(logger: testLogger)

        #expect(observedCount.withLock { $0 } == initialCount + 1)
    }

    @Test
    func pluginAppendedDuringApplyIsIgnored() {
        let didRun = Mutex<Bool>(false)
        let appended = CallbackPlugin { _ in
            didRun.withLock { $0 = true }
        }
        var configuration = Self.makeConfiguration(plugins: [AppendingPlugin(appended: appended)])

        configuration.applyPlugins(logger: testLogger)

        #expect(didRun.withLock { $0 } == false)
        // The list is restored to the plugins that were applied.
        #expect(configuration.plugins.count == 1)
    }

    @Test
    func pluginAppendsReplayerInterceptorOnApply() {
        var configuration = WorkflowReplayer.Configuration(plugins: [AppendInterceptorPlugin()])
        let initialCount = configuration.interceptors.count

        configuration.applyPlugins()

        #expect(configuration.interceptors.count == initialCount + 1)
        #expect(configuration.interceptors.last is SentinelWorkerInterceptor)
    }

    @Test
    func pluginAppendedDuringReplayerApplyIsIgnored() {
        var configuration = WorkflowReplayer.Configuration(plugins: [
            AppendingPlugin(appended: AppendInterceptorPlugin())
        ])

        configuration.applyPlugins()

        #expect(!configuration.interceptors.contains { $0 is SentinelWorkerInterceptor })
        // The list is restored to the plugins that were applied.
        #expect(configuration.plugins.count == 1)
    }
}
