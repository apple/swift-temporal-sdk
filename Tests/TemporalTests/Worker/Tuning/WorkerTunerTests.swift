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
import Synchronization
import Temporal
import TemporalTestKit
import Testing

extension TestServerDependentTests {
    @Suite(.tags(.workflowTests))
    struct WorkerTunerTests {
        @Workflow
        struct SimpleWorkflow {
            mutating func run(context: WorkflowContext<Self>, input: String) async -> String {
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

        @Test
        func customSlotSupplierExecutesWorkflowAndReceivesCallbacks() async throws {
            let taskQueue = "tq-\(UUID().uuidString)"
            let id = "wf-\(UUID().uuidString)"

            let (host, _) = TemporalTestServer.testServer!.hostAndPort()

            let recorder = RecordingCustomSlotSupplier(maximumSlots: 5)

            var config = TemporalWorker.Configuration(
                namespace: "default",
                taskQueue: taskQueue,
                instrumentation: .init(serverHostname: host)
            )
            config.tuner = WorkerTuner(
                workflowSlotSupplier: .custom(recorder),
                activitySlotSupplier: .fixedSize(.init(maximumSlots: 5)),
                localActivitySlotSupplier: .fixedSize(.init(maximumSlots: 5))
            )

            try await withTestWorkerAndClient(
                configuration: config,
                workflows: [SimpleWorkflow.self]
            ) { taskQueue, client in
                let handle = try await client.startWorkflow(
                    type: SimpleWorkflow.self,
                    options: WorkflowOptions(id: id, taskQueue: taskQueue),
                    input: "Custom"
                )
                let result = try await handle.result()
                #expect(result == "Hello, Custom!")
            }

            // We should have observed at least one workflow slot reservation that was both
            // marked used and released, with matching permits each time.
            let events = recorder.recordedEvents
            #expect(events.contains { if case .reserved = $0 { true } else { false } })
            #expect(events.contains { if case .markedUsed = $0 { true } else { false } })
            #expect(events.contains { if case .released = $0 { true } else { false } })

            // Every recorded `markedUsed` and `released` permit must come from a prior reservation.
            let observedPermits = Set(events.compactMap { event -> UUID? in
                switch event {
                case .reserved(let permit), .markedUsed(let permit), .released(let permit):
                    return permit
                }
            })
            for event in events {
                switch event {
                case .markedUsed(let permit), .released(let permit):
                    #expect(observedPermits.contains(permit))
                case .reserved:
                    break
                }
            }
        }
    }
}

/// Test helper that records every slot supplier callback so the test can assert on the sequence
/// of events. Permits are tagged with a UUID so the test can verify the same permit value flows
/// from reserve into mark-used and release.
private final class RecordingCustomSlotSupplier: CustomSlotSupplier {
    struct Permit: Sendable {
        let id: UUID
    }

    enum Event: Sendable {
        case reserved(UUID)
        case markedUsed(UUID)
        case released(UUID)
    }

    private struct State {
        var available: Int
        var events: [Event] = []
    }

    private let state: Mutex<State>
    private let availableContinuation: AsyncStream<Void>.Continuation
    private let availableStream: AsyncStream<Void>

    init(maximumSlots: Int) {
        self.state = Mutex(State(available: maximumSlots))
        let (stream, continuation) = AsyncStream<Void>.makeStream()
        self.availableStream = stream
        self.availableContinuation = continuation
        // Seed the stream so the first reserveSlot can complete immediately.
        for _ in 0..<maximumSlots { continuation.yield() }
    }

    var recordedEvents: [Event] {
        self.state.withLock { $0.events }
    }

    func reserveSlot(context: SlotReserveContext) async throws -> Permit {
        // Wait for an available slot, observing cancellation.
        for await _ in self.availableStream {
            return self.takePermit()
        }
        throw CancellationError()
    }

    func tryReserveSlot(context: SlotReserveContext) -> Permit? {
        self.state.withLock { state in
            guard state.available > 0 else { return nil }
            state.available -= 1
            let permit = Permit(id: UUID())
            state.events.append(.reserved(permit.id))
            return permit
        }
    }

    func markSlotUsed(context: SlotMarkUsedContext<Permit>) {
        self.state.withLock { $0.events.append(.markedUsed(context.permit.id)) }
    }

    func releaseSlot(context: SlotReleaseContext<Permit>) {
        self.state.withLock { state in
            state.available += 1
            state.events.append(.released(context.permit.id))
        }
        self.availableContinuation.yield()
    }

    func availableSlots() -> Int? {
        self.state.withLock { $0.available }
    }

    private func takePermit() -> Permit {
        self.state.withLock { state in
            state.available -= 1
            let permit = Permit(id: UUID())
            state.events.append(.reserved(permit.id))
            return permit
        }
    }
}
