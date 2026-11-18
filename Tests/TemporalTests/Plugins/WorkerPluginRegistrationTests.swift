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

import Temporal
import Testing

@Suite(.tags(.pluginTests))
struct WorkerPluginRegistrationTests {
    @Workflow
    struct PingWorkflow {
        mutating func run(context: WorkflowContext<Self>, input: Void) async throws {}
    }

    @Workflow
    struct ConfiguredWorkflow {
        mutating func run(context: WorkflowContext<Self>, input: Void) async throws {}
    }

    private struct RegistrationPlugin: WorkerPlugin {
        var workflows: [any WorkflowDefinition.Type] { [PingWorkflow.self] }
    }

    @Test
    func replayerApplyAppendsPluginWorkflows() {
        var configuration = WorkflowReplayer.Configuration(
            workflows: [ConfiguredWorkflow.self],
            plugins: [RegistrationPlugin()]
        )

        configuration.applyPlugins()

        #expect(configuration.workflows.count == 2)
        #expect(configuration.workflows.first == ConfiguredWorkflow.self)
        #expect(configuration.workflows.last == PingWorkflow.self)
    }
}
