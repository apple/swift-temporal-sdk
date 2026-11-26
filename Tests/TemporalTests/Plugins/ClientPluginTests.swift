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

@Suite(.tags(.pluginTests))
struct ClientPluginTests {
    private struct NamespaceStampPlugin: ClientPlugin {
        let stamp: String
        func configureClient(_ configuration: inout TemporalClient.Configuration) {
            configuration.namespace = stamp
        }
    }

    private struct SentinelClientInterceptor: ClientInterceptor {}

    private struct AppendInterceptorPlugin: ClientPlugin {
        func configureClient(_ configuration: inout TemporalClient.Configuration) {
            configuration.interceptors.append(SentinelClientInterceptor())
        }
    }

    private struct CallbackPlugin: ClientPlugin {
        let onConfigure: @Sendable (inout TemporalClient.Configuration) -> Void
        func configureClient(_ configuration: inout TemporalClient.Configuration) {
            onConfigure(&configuration)
        }
    }

    private struct AppendingPlugin: ClientPlugin {
        let appended: any ClientPlugin
        func configureClient(_ configuration: inout TemporalClient.Configuration) {
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

        configuration.applyPlugins()

        #expect(configuration.namespace == "second")
    }

    @Test
    func pluginAppendsInterceptorOnApply() {
        var configuration = TemporalClient.Configuration(
            instrumentation: .init(serverHostname: "localhost"),
            plugins: [AppendInterceptorPlugin()]
        )
        let initialCount = configuration.interceptors.count

        configuration.applyPlugins()

        #expect(configuration.interceptors.count == initialCount + 1)
        #expect(configuration.interceptors.last is SentinelClientInterceptor)
    }

    @Test
    func pluginAppendedDuringApplyIsIgnored() {
        let didRun = Mutex<Bool>(false)
        let appended = CallbackPlugin { _ in
            didRun.withLock { $0 = true }
        }
        var configuration = TemporalClient.Configuration(
            instrumentation: .init(serverHostname: "localhost"),
            plugins: [AppendingPlugin(appended: appended)]
        )

        configuration.applyPlugins()

        #expect(didRun.withLock { $0 } == false)
        #expect(configuration.plugins.count == 1)
    }

    @Test
    func laterPluginObservesEarlierPluginMutations() {
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

        configuration.applyPlugins()

        #expect(observedCount.withLock { $0 } == initialCount + 1)
    }
}
