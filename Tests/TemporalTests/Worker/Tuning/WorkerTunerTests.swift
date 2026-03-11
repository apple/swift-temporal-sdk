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
    @Suite(.tags(.workflowTests))
    struct WorkerTunerTests {
        @Workflow
        final class SimpleWorkflow {
            func run(input: String) async -> String {
                return "Hello, \(input)!"
            }
        }

        @Test
        func fixedSizeTunerExecutesWorkflow() async throws {
            let taskQueue = "tq-\(UUID().uuidString)"
            let id = "wf-\(UUID().uuidString)"

            try await withTestWorkerAndClient(
                taskQueue: taskQueue,
                workflows: [SimpleWorkflow.self]
            ) { taskQueue, client in
                let handle = try await client.startWorkflow(
                    type: SimpleWorkflow.self,
                    options: WorkflowOptions(id: id, taskQueue: taskQueue),
                    input: "Tuner"
                )
                let result = try await handle.result()
                #expect(result == "Hello, Tuner!")
            }
        }

        @Test
        func resourceBasedTunerExecutesWorkflow() async throws {
            let taskQueue = "tq-\(UUID().uuidString)"
            let id = "wf-\(UUID().uuidString)"

            let (host, _) = TemporalTestServer.testServer!.hostAndPort()

            var config = TemporalWorker.Configuration(
                namespace: "default",
                taskQueue: taskQueue,
                instrumentation: .init(serverHostname: host)
            )
            config.tuner = .resourceBased(
                targetMemoryUsage: 0.8,
                targetCpuUsage: 0.9
            )

            try await withTestWorkerAndClient(
                configuration: config,
                workflows: [SimpleWorkflow.self]
            ) { taskQueue, client in
                let handle = try await client.startWorkflow(
                    type: SimpleWorkflow.self,
                    options: WorkflowOptions(id: id, taskQueue: taskQueue),
                    input: "ResourceBased"
                )
                let result = try await handle.result()
                #expect(result == "Hello, ResourceBased!")
            }
        }

        @Test
        func explicitFixedSizeTunerExecutesWorkflow() async throws {
            let taskQueue = "tq-\(UUID().uuidString)"
            let id = "wf-\(UUID().uuidString)"

            let (host, _) = TemporalTestServer.testServer!.hostAndPort()

            var config = TemporalWorker.Configuration(
                namespace: "default",
                taskQueue: taskQueue,
                instrumentation: .init(serverHostname: host)
            )
            config.tuner = WorkerTuner(
                workflowSlotSupplier: .fixedSize(.init(maximumSlots: 50)),
                activitySlotSupplier: .fixedSize(.init(maximumSlots: 200)),
                localActivitySlotSupplier: .fixedSize(.init(maximumSlots: 75))
            )

            try await withTestWorkerAndClient(
                configuration: config,
                workflows: [SimpleWorkflow.self]
            ) { taskQueue, client in
                let handle = try await client.startWorkflow(
                    type: SimpleWorkflow.self,
                    options: WorkflowOptions(id: id, taskQueue: taskQueue),
                    input: "FixedSize"
                )
                let result = try await handle.result()
                #expect(result == "Hello, FixedSize!")
            }
        }
    }
}
