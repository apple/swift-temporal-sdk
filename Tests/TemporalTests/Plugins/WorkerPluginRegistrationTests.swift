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
import Temporal
import Testing

private let testLogger = Logger(label: "test")

private struct PluginRegistrationPingActivity: ActivityDefinition {
    typealias Input = Void
    typealias Output = Void

    static let name: String? = "PluginRegistrationPingActivity"

    func run(input: Void) async throws {}
}

@Workflow
struct PluginRegistrationPingWorkflow {
    mutating func run(context: WorkflowContext<Self>, input: Void) async throws {}
}

@Suite(.tags(.pluginTests))
struct WorkerPluginRegistrationTests {
    private struct RegistrationPlugin: WorkerPlugin {
        var activities: [any ActivityDefinition] { [PluginRegistrationPingActivity()] }
        var workflows: [any WorkflowDefinition.Type] { [PluginRegistrationPingWorkflow.self] }
    }

    @Test
    func replayerFoldAppendsPluginContributedWorkflows() {
        // Mirrors the fold performed by WorkflowReplayer.Configuration.applyPlugins(): it appends
        // plugin-contributed workflows to configuration.workflows. We exercise the same path here
        // so the pass criterion is an explicit assertion rather than a non-trapping precondition.
        var configuration = WorkflowReplayer.Configuration(
            workflows: [],
            plugins: [RegistrationPlugin()]
        )

        configuration.applyPlugins()

        #expect(configuration.workflows.contains { $0 == PluginRegistrationPingWorkflow.self })
    }

    @Test
    func workerApplyPluginsReturnsPluginContributionsForFold() {
        // TemporalWorker.init folds plugin-contributed activities and workflows into the
        // worker registration by reading the snapshot that `applyPlugins()` returns. Spinning
        // up a real TemporalWorker requires a transport and bridge runtime, so this test
        // exercises the same snapshot directly.
        var configuration = TemporalWorker.Configuration(
            namespace: "test",
            taskQueue: "test-queue",
            instrumentation: .init(serverHostname: "localhost"),
            plugins: [RegistrationPlugin()]
        )

        let plugins = configuration.applyPlugins(logger: testLogger)

        #expect(plugins.count == 1)
        #expect(plugins[0].activities.count == 1)
        #expect(type(of: plugins[0].activities[0]).name == "PluginRegistrationPingActivity")
        #expect(plugins[0].workflows.count == 1)
        #expect(plugins[0].workflows[0] == PluginRegistrationPingWorkflow.self)
    }
}
