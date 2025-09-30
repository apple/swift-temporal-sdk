//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Temporal SDK open source project
//
// Copyright (c) 2025 Apple Inc. and the Swift Temporal SDK project authors
// Licensed under MIT License
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Swift Temporal SDK project authors
//
// SPDX-License-Identifier: MIT
//
//===----------------------------------------------------------------------===//

import GRPCCore
import Logging
import ServiceLifecycle
import Synchronization
import Temporal
import Testing

extension TestServerDependentTests {
    @Suite(.timeLimit(.minutes(1)))
    struct TemporalWorkerErrorTests {
        // TODO: Re-enable this test as soon as the fired RPC isn't stuck anymore indefinitely when the GRPCClient doesn't properly start up
        //        @Test
        //        func workerTaskQueueError() async throws {
        //            struct TestGRPCClient: UnaryGRPCClient {
        //                let run: @Sendable () async throws -> Void
        //                let unary: UnaryCall<UInt8ArraySerializer, UInt8ArrayDeserializer>
        //                let beginGracefulShutdown: @Sendable () -> Void
        //                init(
        //                    run: @Sendable @escaping () async throws -> Void,
        //                    unary: @escaping UnaryCall<UInt8ArraySerializer, UInt8ArrayDeserializer>,
        //                    beginGracefulShutdown: @Sendable @escaping () -> Void
        //                ) {
        //                    self.run = {
        //                        throw TestError()
        //                    }
        //                    self.unary = unary
        //                    self.beginGracefulShutdown = beginGracefulShutdown
        //                }
        //            }
        //
        //            await #expect(throws: TestError.self) {
        //                try await withTestWorkerAndClient(
        //                    workerType: GenericTemporalWorker<BridgeWorker, WorkflowWorker<BridgeWorker>, ActivityWorker<BridgeWorker>, TestGRPCClient>.self
        //                ) { taskQueue, client in
        //                    try await Task.sleep(for: .seconds(1000))
        //                }
        //            }
        //        }

        @Test
        func activityWorkerError() async throws {
            final class MockActivityWorker: ActivityWorkerForwarding {
                let base: ActivityWorker<BridgeWorker>
                let count = Mutex(0)

                required init(
                    worker: BridgeWorker,
                    configuration: TemporalWorker.Configuration,
                    activities: [any ActivityDefinition],
                    logger: Logger
                ) {
                    self.base = ActivityWorker(
                        worker: worker,
                        configuration: configuration,
                        activities: activities,
                        logger: logger
                    )
                }

                func run() async throws {
                    try self.count.withLock { count in
                        if count == 0 {
                            count += 1
                            throw TestError()
                        }
                    }

                    try await base.run()
                }
            }

            await #expect(throws: TestError.self) {
                try await withTestWorkerAndClient(
                    workerType: GenericTemporalWorker<BridgeWorker, WorkflowWorker<BridgeWorker>, MockActivityWorker, AnyUInt8GRPCClient>.self
                ) { _, _ in
                    try await Task.sleep(for: .seconds(1000))
                }
            }
        }

        @Test
        func workflowWorkerError() async throws {
            final class MockWorkflowWorker: WorkflowWorkerForwarding {
                let base: WorkflowWorker<BridgeWorker>
                let count = Mutex(0)

                required init(
                    worker: BridgeWorker,
                    configuration: TemporalWorker.Configuration,
                    workflows: [any WorkflowDefinition.Type],
                    logger: Logger
                ) {
                    self.base = WorkflowWorker(
                        worker: worker,
                        configuration: configuration,
                        workflows: workflows,
                        logger: logger
                    )
                }

                func run() async throws {
                    try self.count.withLock { count in
                        if count == 0 {
                            count += 1
                            throw TestError()
                        }
                    }

                    try await self.base.run()
                }
            }

            await #expect(throws: TestError.self) {
                try await withTestWorkerAndClient(
                    workerType: GenericTemporalWorker<BridgeWorker, MockWorkflowWorker, ActivityWorker<BridgeWorker>, AnyUInt8GRPCClient>.self
                ) { _, _ in
                    try await Task.sleep(for: .seconds(1000))
                }
            }
        }

        @Test
        func pollWorkflowActivationError() async throws {
            final class MockBridgeWorker: BridgeWorkerForwarding {
                let base: BridgeWorker

                init(
                    client: borrowing Temporal.BridgeClient,
                    configuration: Temporal.TemporalWorker.Configuration
                ) throws {
                    self.base = try BridgeWorker(
                        client: client,
                        configuration: configuration
                    )
                }

                func pollWorkflowActivation() async throws -> Coresdk_WorkflowActivation_WorkflowActivation {
                    throw TestError()
                }
            }

            await #expect(throws: TestError.self) {
                try await withTestWorkerAndClient(
                    workerType: GenericTemporalWorker<
                        MockBridgeWorker, WorkflowWorker<MockBridgeWorker>, ActivityWorker<MockBridgeWorker>, AnyUInt8GRPCClient
                    >.self
                ) { _, _ in
                    try await Task.sleep(for: .seconds(1000))
                }
            }
        }
    }
}
