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

    private struct AppendInterceptorPlugin: WorkerPlugin {
        func configure(_ configuration: inout TemporalWorker.Configuration) {
            configuration.interceptors.append(SentinelWorkerInterceptor())
        }

        func configureReplayer(_ configuration: inout WorkflowReplayer.Configuration) {
            configuration.interceptors.append(SentinelWorkerInterceptor())
        }
    }

    private struct WorkerOnlyPlugin: WorkerPlugin {
        func configure(_ configuration: inout TemporalWorker.Configuration) {
            configuration.interceptors.append(SentinelWorkerInterceptor())
        }
    }

    /// Invokes `onConfigure` when its ``configure(_:)`` runs.
    private struct CallbackPlugin: WorkerPlugin {
        let onConfigure: @Sendable (inout TemporalWorker.Configuration) -> Void
        func configure(_ configuration: inout TemporalWorker.Configuration) {
            onConfigure(&configuration)
        }
    }

    /// Appends a ``WorkerPlugin`` to ``TemporalWorker/Configuration/plugins`` inside its own ``configure(_:)``.
    ///
    /// The documented invariant says the plugin list is captured before the first plugin runs, so
    /// the appended plugin must not run in the same apply pass.
    private struct SelfModifyingAppenderPlugin: WorkerPlugin {
        let appended: any WorkerPlugin
        func configure(_ configuration: inout TemporalWorker.Configuration) {
            configuration.plugins.append(appended)
        }
    }

    @Test
    func pluginAppendsWorkerInterceptorOnApply() {
        var configuration = TemporalWorker.Configuration(
            namespace: "test",
            taskQueue: "test-queue",
            instrumentation: .init(serverHostname: "localhost"),
            plugins: [AppendInterceptorPlugin()]
        )
        let initialCount = configuration.interceptors.count

        configuration.applyPlugins(logger: testLogger)

        #expect(configuration.interceptors.count == initialCount + 1)
        #expect(configuration.interceptors.last is SentinelWorkerInterceptor)
    }

    @Test
    func pluginAppendsReplayerInterceptorOnApply() {
        var configuration = WorkflowReplayer.Configuration(
            plugins: [AppendInterceptorPlugin()]
        )
        let initialCount = configuration.interceptors.count

        configuration.applyPlugins()

        #expect(configuration.interceptors.count == initialCount + 1)
        #expect(configuration.interceptors.last is SentinelWorkerInterceptor)
    }

    @Test
    func workerOnlyPluginIsNoOpForReplayer() {
        var configuration = WorkflowReplayer.Configuration(
            plugins: [WorkerOnlyPlugin()]
        )
        let initialCount = configuration.interceptors.count

        configuration.applyPlugins()

        #expect(configuration.interceptors.count == initialCount)
        // The replayer interceptor list must be unchanged: no SentinelWorkerInterceptor
        // can leak in via the worker-only configure(_:) path.
        #expect(!configuration.interceptors.contains { $0 is SentinelWorkerInterceptor })
    }

    @Test
    func selfAppendedPluginDoesNotRunInSameApplyPass() {
        let didRun = Mutex<Bool>(false)
        let appended = CallbackPlugin { _ in
            didRun.withLock { $0 = true }
        }
        var configuration = TemporalWorker.Configuration(
            namespace: "test",
            taskQueue: "test-queue",
            instrumentation: .init(serverHostname: "localhost"),
            plugins: [SelfModifyingAppenderPlugin(appended: appended)]
        )

        configuration.applyPlugins(logger: testLogger)

        #expect(didRun.withLock { $0 } == false)
        // The appender did append; the captured snapshot just didn't replay.
        #expect(configuration.plugins.count == 2)
    }
}
