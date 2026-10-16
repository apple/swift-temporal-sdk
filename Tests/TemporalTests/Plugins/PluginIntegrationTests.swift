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

import Foundation
import GRPCNIOTransportHTTP2Posix
import Logging
import ServiceLifecycle
import Synchronization
import Temporal
import TemporalTestKit
import Testing

extension TestServerDependentTests {
    @Suite(.tags(.pluginTests))
    struct PluginIntegrationTests {
        struct GreetingActivity: ActivityDefinition {
            static let name: String? = "PluginGreetingActivity"

            func run(input name: String) async throws -> String {
                "Hello, \(name)!"
            }
        }

        @Workflow
        struct GreetingWorkflow {
            mutating func run(context: WorkflowContext<Self>, input name: String) async throws -> String {
                try await context.executeActivity(
                    GreetingActivity.self,
                    options: .init(scheduleToCloseTimeout: .seconds(60)),
                    input: name
                )
            }
        }

        private struct GreetingPlugin: WorkerPlugin {
            var activities: [any ActivityDefinition] { [GreetingActivity()] }
            var workflows: [any WorkflowDefinition.Type] { [GreetingWorkflow.self] }
        }

        /// Ends the worker's run without an error by never calling `next`.
        private struct EarlyReturnPlugin: WorkerPlugin {
            func runWorker(configuration: TemporalWorker.Configuration, next: () async throws -> Void) async throws {}
        }

        /// Installs ``MarkerPayloadCodec``, so a hook can check that it received the configuration
        /// the plugins produced.
        private static func withMarkerCodec(_ existing: DataConverter) -> DataConverter {
            DataConverter(
                payloadConverter: existing.payloadConverter,
                failureConverter: existing.failureConverter,
                payloadCodec: MarkerPayloadCodec()
            )
        }

        private static func workerConfiguration(plugins: [any WorkerPlugin]) -> TemporalWorker.Configuration {
            let (host, _) = TemporalTestServer.testServer!.hostAndPort()
            return TemporalWorker.Configuration(
                namespace: "default",
                taskQueue: UUID().uuidString,
                instrumentation: .init(serverHostname: host),
                plugins: plugins
            )
        }

        @Test
        func pluginActivityAndWorkflowRunOnWorkerAndReplay() async throws {
            // Neither is passed to the worker or replayer directly; both come from the plugin.
            try await withTestWorkerAndClient(
                configuration: Self.workerConfiguration(plugins: [GreetingPlugin()])
            ) { taskQueue, client in
                let handle = try await client.startWorkflow(
                    type: GreetingWorkflow.self,
                    options: .init(id: "plugin-\(UUID().uuidString)", taskQueue: taskQueue),
                    input: "plugin"
                )
                #expect(try await handle.result() == "Hello, plugin!")

                let replayer = WorkflowReplayer(configuration: .init(plugins: [GreetingPlugin()]))
                let replay = try await replayer.replayWorkflow(history: try await handle.fetchHistory())
                #expect(replay.replayFailure == nil)
            }
        }

        @Test
        func hooksWrapWorkerRunAndEachReplay() async throws {
            let events = Mutex<[String]>([])
            let plugin = SimplePlugin(
                name: "test",
                dataConverter: { Self.withMarkerCodec($0) },
                activities: [GreetingActivity()],
                workflows: [GreetingWorkflow.self],
                beforeRunWorker: { configuration in
                    #expect(configuration.dataConverter.payloadCodec is MarkerPayloadCodec)
                    events.withLock { $0.append("beforeRunWorker") }
                },
                afterRunWorker: { _ in events.withLock { $0.append("afterRunWorker") } },
                beforeRunReplayer: { configuration in
                    #expect(configuration.dataConverter.payloadCodec is MarkerPayloadCodec)
                    events.withLock { $0.append("beforeRunReplayer") }
                },
                afterRunReplayer: { _ in events.withLock { $0.append("afterRunReplayer") } }
            )

            try await withTestWorkerAndClient(
                configuration: Self.workerConfiguration(plugins: [plugin])
            ) { taskQueue, client in
                let handle = try await client.startWorkflow(
                    type: GreetingWorkflow.self,
                    options: .init(id: "plugin-\(UUID().uuidString)", taskQueue: taskQueue),
                    input: "plugin"
                )
                _ = try await handle.result()

                let history = try await handle.fetchHistory()
                let replayer = WorkflowReplayer(configuration: .init(plugins: [plugin]))
                _ = try await replayer.replayWorkflows(histories: [history, history])
            }

            // The worker is cancelled once the body returns, so its after closure runs last.
            #expect(
                events.withLock { $0 } == [
                    "beforeRunWorker",
                    "beforeRunReplayer", "afterRunReplayer",
                    "beforeRunReplayer", "afterRunReplayer",
                    "afterRunWorker",
                ]
            )
        }

        @Test
        func hooksWrapThePublicWorkerRun() async throws {
            let events = Mutex<[String]>([])
            let plugin = SimplePlugin(
                name: "test",
                activities: [GreetingActivity()],
                workflows: [GreetingWorkflow.self],
                beforeRunWorker: { _ in events.withLock { $0.append("before") } },
                afterRunWorker: { _ in events.withLock { $0.append("after") } }
            )
            let configuration = Self.workerConfiguration(plugins: [plugin])
            let (host, port) = TemporalTestServer.testServer!.hostAndPort()
            let worker = try TemporalWorker(
                configuration: configuration,
                target: .dns(host: host, port: port),
                transportSecurity: .plaintext,
                logger: Logger(label: "worker")
            )
            let serviceGroup = ServiceGroup(
                configuration: .init(services: [worker], logger: Logger(label: "service-group"))
            )

            try await withThrowingTaskGroup(of: Void.self) { group in
                group.addTask { try? await serviceGroup.run() }
                // A completed workflow shows the worker is polling, so the shutdown can't race its start.
                try await withTestClient { client in
                    let handle = try await client.startWorkflow(
                        type: GreetingWorkflow.self,
                        options: .init(id: "plugin-\(UUID().uuidString)", taskQueue: configuration.taskQueue),
                        input: "plugin"
                    )
                    _ = try await handle.result()
                }
                await serviceGroup.triggerGracefulShutdown()
            }

            #expect(events.withLock { $0 } == ["before", "after"])
        }

        @Test
        func connectedWorkerThrowsWhenTheWorkerStopsBeforeTheBody() async throws {
            await #expect(throws: (any Error).self) {
                try await TemporalTestServer.testServer!.withConnectedWorker(
                    configuration: Self.workerConfiguration(plugins: [EarlyReturnPlugin()])
                ) { _ in
                    try await Task.sleep(for: .seconds(60))
                }
            }
        }

        @Test
        func connectAppliesPluginsAndWrapsTheBody() async throws {
            let events = Mutex<[String]>([])
            let plugin = SimplePlugin(
                name: "test",
                dataConverter: { existing in
                    events.withLock { $0.append("configure") }
                    return Self.withMarkerCodec(existing)
                },
                beforeConnect: { configuration in
                    #expect(configuration.dataConverter.payloadCodec is MarkerPayloadCodec)
                    events.withLock { $0.append("before") }
                },
                afterConnect: { _ in events.withLock { $0.append("after") } }
            )
            let (host, port) = TemporalTestServer.testServer!.hostAndPort()

            try await TemporalClient.connect(
                transport: .http2NIOPosix(target: .dns(host: host, port: port), transportSecurity: .plaintext),
                configuration: .init(instrumentation: .init(serverHostname: host), plugins: [plugin])
            ) { client in
                // A body that returns before the connections start makes `withGRPCClient` throw
                // `clientIsStopped`, and an RPC can't complete until they have.
                _ = try await client.namespaceService.describeNamespace(namespace: .name("default"))
                events.withLock { $0.append("body") }
            }

            #expect(events.withLock { $0 } == ["configure", "before", "body", "after"])
        }

        @Test
        func serviceClientAppliesPluginsAtInitAndWrapsRun() async throws {
            let events = Mutex<[String]>([])
            let plugin = SimplePlugin(
                name: "test",
                dataConverter: { existing in
                    events.withLock { $0.append("configure") }
                    return Self.withMarkerCodec(existing)
                },
                beforeConnect: { configuration in
                    #expect(configuration.dataConverter.payloadCodec is MarkerPayloadCodec)
                    events.withLock { $0.append("before") }
                },
                afterConnect: { _ in events.withLock { $0.append("after") } }
            )
            let (host, port) = TemporalTestServer.testServer!.hostAndPort()

            let client = TemporalClient(
                transport: try .http2NIOPosix(target: .dns(host: host, port: port), transportSecurity: .plaintext),
                configuration: .init(instrumentation: .init(serverHostname: host), plugins: [plugin])
            )
            #expect(events.withLock { $0 } == ["configure"])

            try await withThrowingDiscardingTaskGroup { group in
                group.addTask { try await client.run() }
                // An RPC only completes once the client is running, so shutting down after it
                // can't race the start of `run()`.
                _ = try await client.namespaceService.describeNamespace(namespace: .name("default"))
                client.beginGracefulShutdown()
            }

            #expect(events.withLock { $0 } == ["configure", "before", "after"])
        }
    }
}
