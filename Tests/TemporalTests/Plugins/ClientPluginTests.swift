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
struct ClientPluginTests {
    private struct NamespaceStampPlugin: ClientPlugin {
        let stamp: String
        func configure(_ configuration: inout TemporalClient.Configuration) {
            configuration.namespace = stamp
        }
    }

    /// Sentinel ClientInterceptor used to verify type identity of the appended interceptor.
    ///
    /// `ClientInterceptor` provides defaults for all requirements, so the conformance is empty.
    private struct SentinelClientInterceptor: ClientInterceptor {}

    private struct AppendInterceptorPlugin: ClientPlugin {
        func configure(_ configuration: inout TemporalClient.Configuration) {
            configuration.interceptors.append(SentinelClientInterceptor())
        }
    }

    /// Invokes `onConfigure` when its ``configure(_:)`` runs.
    ///
    /// Tests use this to detect whether a plugin ran on its expected side-channel.
    private struct CallbackPlugin: ClientPlugin {
        let onConfigure: @Sendable (inout TemporalClient.Configuration) -> Void
        func configure(_ configuration: inout TemporalClient.Configuration) {
            onConfigure(&configuration)
        }
    }

    /// Appends a ``ClientPlugin`` to ``TemporalClient/Configuration/plugins`` inside its own ``configure(_:)``.
    ///
    /// The documented invariant says the plugin list is captured before the first plugin runs, so
    /// the appended plugin must not run in the same apply pass.
    private struct SelfModifyingAppenderPlugin: ClientPlugin {
        let appended: any ClientPlugin
        func configure(_ configuration: inout TemporalClient.Configuration) {
            configuration.plugins.append(appended)
        }
    }

    @Test
    func pluginsRunInArrayOrderOnApply() {
        var configuration = TemporalClient.Configuration(
            instrumentation: .init(serverHostname: "localhost"),
            plugins: [
                NamespaceStampPlugin(stamp: "first"),
                NamespaceStampPlugin(stamp: "second"),
            ]
        )

        configuration.applyPlugins(logger: testLogger)

        #expect(configuration.namespace == "second")
    }

    @Test
    func pluginAppendsInterceptorOnApply() {
        var configuration = TemporalClient.Configuration(
            instrumentation: .init(serverHostname: "localhost"),
            plugins: [AppendInterceptorPlugin()]
        )
        let initialCount = configuration.interceptors.count

        configuration.applyPlugins(logger: testLogger)

        #expect(configuration.interceptors.count == initialCount + 1)
        #expect(configuration.interceptors.last is SentinelClientInterceptor)
    }

    @Test
    func selfAppendedPluginDoesNotRunInSameApplyPass() {
        let didRun = Mutex<Bool>(false)
        let appended = CallbackPlugin { _ in
            didRun.withLock { $0 = true }
        }
        var configuration = TemporalClient.Configuration(
            instrumentation: .init(serverHostname: "localhost"),
            plugins: [SelfModifyingAppenderPlugin(appended: appended)]
        )

        configuration.applyPlugins(logger: testLogger)

        #expect(didRun.withLock { $0 } == false)
        // The appender did append; the captured snapshot just didn't replay.
        #expect(configuration.plugins.count == 2)
    }

    @Test
    func laterPluginObservesEarlierPluginMutations() {
        // PluginA appends an interceptor; PluginB records the interceptor count it sees.
        // If plugins compose on a shared configuration value, B's observed count must reflect
        // A's append.
        let observedCount = Mutex<Int?>(nil)
        var configuration = TemporalClient.Configuration(
            instrumentation: .init(serverHostname: "localhost"),
            plugins: [
                AppendInterceptorPlugin(),
                CallbackPlugin { configuration in
                    observedCount.withLock { $0 = configuration.interceptors.count }
                },
            ]
        )
        let initialCount = configuration.interceptors.count

        configuration.applyPlugins(logger: testLogger)

        #expect(observedCount.withLock { $0 } == initialCount + 1)
    }

    @Test
    func defaultNameMatchesTypeName() {
        let plugin = NamespaceStampPlugin(stamp: "x")
        #expect(plugin.name == "NamespaceStampPlugin")
    }
}
