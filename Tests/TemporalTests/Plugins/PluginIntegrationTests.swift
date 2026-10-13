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
    }
}
