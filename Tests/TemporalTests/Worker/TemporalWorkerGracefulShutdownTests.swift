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

import GRPCNIOTransportCore
import GRPCNIOTransportHTTP2Posix
import Logging
import ServiceLifecycle
import Synchronization
import Temporal
import TemporalTestKit
import Testing

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

extension TestServerDependentTests {
    @Suite
    struct TemporalWorkerGracefulShutdownTests {
        @Workflow
        struct SimpleWorkflow {
            mutating func run(context: WorkflowContext<Self>, input: Void) async throws {
                try await context.sleep(for: .seconds(1000))
            }
        }

        @Test
        func gracefullyShutdownWorker() async throws {
            struct ExecuteWorkflowService: Service {
                func run() async throws {
                    try await executeWorkflow(
                        SimpleWorkflow.self,
                        input: ()
                    )
                }
            }
            let serviceGroup = ServiceGroup(
                services: [ExecuteWorkflowService()],
                logger: Logger(label: "TestLogger")
            )
            await withThrowingTaskGroup { group in
                group.addTask {
                    try await serviceGroup.run()
                }
                await serviceGroup.triggerGracefulShutdown()

                await #expect(throws: (any Error).self) {
                    try await group.waitForAll()
                }
            }
        }

        final class Signal: Sendable {
            let started = Mutex(false)
            let cancelledEarly = Mutex(false)
        }

        struct HeartbeatingActivity: ActivityDefinition {
            static let name: String? = "HeartbeatingActivity"
            let signal: Signal

            func run(input: Void) async throws {
                let context = ActivityExecutionContext.current!
                signal.started.withLock { $0 = true }
                // If the heartbeat timeout is exceeded, the server sends a cancellation.
                // Run the heartbeat activity for long enough to guarantee it was not cancelled.
                let deadline = ContinuousClock.now.advanced(by: .seconds(20))
                while ContinuousClock.now < deadline {
                    // If graceful shutdown stops heartbeat delivery,
                    // this activity gets cancelled early.
                    if Task.isCancelled {
                        signal.cancelledEarly.withLock { $0 = true }
                        return
                    }
                    context.heartbeat(details: "beat")
                    try? await Task.sleep(for: .milliseconds(200))
                }
            }
        }

        @Workflow
        struct HeartbeatWorkflow {
            mutating func run(context: WorkflowContext<Self>, input: Void) async throws {
                var options = ActivityOptions(startToCloseTimeout: .seconds(60))
                options.heartbeatTimeout = .seconds(1)
                try await context.executeActivity(HeartbeatingActivity.self, options: options, input: ())
            }
        }

        @Test
        func activityKeepsHeartbeatingDuringGracefulShutdown() async throws {
            let signal = Signal()
            let (host, port) = TemporalTestServer.testServer!.hostAndPort()
            let taskQueue = "tq-\(UUID().uuidString)"

            var configuration = TemporalWorker.Configuration(
                namespace: "default",
                taskQueue: taskQueue,
                instrumentation: .init(serverHostname: host)
            )
            configuration.gracefulShutdownPeriod = .seconds(30)
            configuration.maxHeartbeatThrottleInterval = .seconds(1)

            let worker = try TemporalWorker(
                configuration: configuration,
                target: .dns(host: host, port: port),
                transportSecurity: .plaintext,
                activities: [HeartbeatingActivity(signal: signal)],
                workflows: [HeartbeatWorkflow.self],
                logger: Logger(label: "worker")
            )
            let serviceGroup = ServiceGroup(
                configuration: .init(services: [worker], logger: Logger(label: "service-group"))
            )

            await withTaskGroup(of: Void.self) { group in
                group.addTask { try? await serviceGroup.run() }
                try? await withTestClient { client in
                    _ = try await client.startWorkflow(
                        type: HeartbeatWorkflow.self,
                        options: .init(id: "wf-\(UUID().uuidString)", taskQueue: taskQueue),
                        input: ()
                    )
                    while !signal.started.withLock({ $0 }) { try await Task.sleep(for: .milliseconds(50)) }
                    await serviceGroup.triggerGracefulShutdown()
                }
                await group.waitForAll()
            }

            #expect(
                !signal.cancelledEarly.withLock { $0 },
                "activity heartbeat timed-out during graceful shutdown"
            )
        }
    }
}
