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
import Logging
import Synchronization
import Temporal
import TemporalTestKit
import Testing

extension TestServerDependentTests {
    @Suite(.tags(.workflowTests))
    struct HandlerUnfinishedPolicyIntegrationTests {
        @Workflow
        struct UnfinishedSignalWorkflow {
            private var signalReceived = false

            mutating func run(context: WorkflowContext<Self>, input: Void) async throws {
                try await context.condition { $0.signalReceived }
            }

            @WorkflowSignal
            mutating func warnSignal(context: WorkflowContext<Self>, input: Void) async throws {
                self.signalReceived = true
                try await context.sleep(for: .seconds(999_999))
            }

            @WorkflowSignal(unfinishedPolicy: .abandon)
            mutating func abandonSignal(context: WorkflowContext<Self>, input: Void) async throws {
                self.signalReceived = true
                try await context.sleep(for: .seconds(999_999))
            }
        }

        @Workflow
        struct UnfinishedUpdateWorkflow {
            private var updateReceived = false

            mutating func run(context: WorkflowContext<Self>, input: Void) async throws {
                try await context.condition { $0.updateReceived }
            }

            @WorkflowUpdate
            mutating func warnUpdate(context: WorkflowContext<Self>, input: Void) async throws -> String {
                self.updateReceived = true
                try await context.sleep(for: .seconds(999_999))
                return "done"
            }

            @WorkflowUpdate(unfinishedPolicy: .abandon)
            mutating func abandonUpdate(context: WorkflowContext<Self>, input: Void) async throws -> String {
                self.updateReceived = true
                try await context.sleep(for: .seconds(999_999))
                return "done"
            }
        }

        @Test
        func warnAndAbandonSignalAppearsInWarning() async throws {
            let logHandler = InMemoryLogHandler()
            let workerLogger = Logger(label: "TestWorker", factory: { _ in logHandler })

            try await withTestWorkerAndClient(
                workflows: [UnfinishedSignalWorkflow.self],
                workerLogger: workerLogger
            ) { taskQueue, client in
                let handle = try await client.startWorkflow(
                    type: UnfinishedSignalWorkflow.self,
                    options: .init(id: UUID().uuidString, taskQueue: taskQueue)
                )

                try await handle.signal(signalType: UnfinishedSignalWorkflow.WarnSignal.self)
                try await handle.result()

                let infoEntries = logHandler.entries.withLock { entries in
                    entries.filter { $0.level == .info }
                }
                let warningEntry = infoEntries.first {
                    "\($0.message)".contains("Workflow finished while signal or update handlers are still running")
                }

                #expect(warningEntry != nil, "Expected an unfinished handler warning at info level")
                if let entry = warningEntry, let metadata = entry.metadata {
                    let signalMeta = metadata["temporal.workflow.unfinished.signals"]
                    #expect(signalMeta != nil, "Expected signal metadata key")
                    if let signalMeta {
                        #expect("\(signalMeta)".contains("WarnSignal"), "Expected metadata to mention WarnSignal")
                    }
                }
            }
        }

        @Test
        func abandonSignalDoesNotAppearInWarning() async throws {
            let logHandler = InMemoryLogHandler()
            let workerLogger = Logger(label: "TestWorker", factory: { _ in logHandler })

            try await withTestWorkerAndClient(
                workflows: [UnfinishedSignalWorkflow.self],
                workerLogger: workerLogger
            ) { taskQueue, client in
                let handle = try await client.startWorkflow(
                    type: UnfinishedSignalWorkflow.self,
                    options: .init(id: UUID().uuidString, taskQueue: taskQueue)
                )

                try await handle.signal(signalType: UnfinishedSignalWorkflow.AbandonSignal.self)
                try await handle.result()

                let allMessages = logHandler.entries.withLock { entries in
                    entries.map { "\($0.message)" }
                }
                let unfinishedWarning = allMessages.first {
                    $0.contains("Workflow finished while signal or update handlers are still running")
                }

                #expect(
                    unfinishedWarning == nil,
                    "Expected no unfinished handler warning when only .abandon handlers are unfinished"
                )
            }
        }

        @Test
        func warnAndAbandonUpdateAppearsInWarning() async throws {
            let logHandler = InMemoryLogHandler()
            let workerLogger = Logger(label: "TestWorker", factory: { _ in logHandler })

            try await withTestWorkerAndClient(
                workflows: [UnfinishedUpdateWorkflow.self],
                workerLogger: workerLogger
            ) { taskQueue, client in
                let handle = try await client.startWorkflow(
                    type: UnfinishedUpdateWorkflow.self,
                    options: .init(id: UUID().uuidString, taskQueue: taskQueue)
                )

                _ = try await handle.startUpdate(
                    updateType: UnfinishedUpdateWorkflow.WarnUpdate.self,
                    waitForStage: .accepted,
                    input: ()
                )
                try await handle.result()

                let infoEntries = logHandler.entries.withLock { entries in
                    entries.filter { $0.level == .info }
                }
                let warningEntry = infoEntries.first {
                    "\($0.message)".contains("Workflow finished while signal or update handlers are still running")
                }

                #expect(warningEntry != nil, "Expected an unfinished handler warning at info level")
                if let entry = warningEntry, let metadata = entry.metadata {
                    let updateMeta = metadata["temporal.workflow.unfinished.updates"]
                    #expect(updateMeta != nil, "Expected update metadata key")
                    if let updateMeta {
                        #expect("\(updateMeta)".contains("WarnUpdate"), "Expected metadata to mention WarnUpdate")
                    }
                }
            }
        }

        @Test
        func abandonUpdateDoesNotAppearInWarning() async throws {
            let logHandler = InMemoryLogHandler()
            let workerLogger = Logger(label: "TestWorker", factory: { _ in logHandler })

            try await withTestWorkerAndClient(
                workflows: [UnfinishedUpdateWorkflow.self],
                workerLogger: workerLogger
            ) { taskQueue, client in
                let handle = try await client.startWorkflow(
                    type: UnfinishedUpdateWorkflow.self,
                    options: .init(id: UUID().uuidString, taskQueue: taskQueue)
                )

                _ = try await handle.startUpdate(
                    updateType: UnfinishedUpdateWorkflow.AbandonUpdate.self,
                    waitForStage: .accepted,
                    input: ()
                )
                try await handle.result()

                let allMessages = logHandler.entries.withLock { entries in
                    entries.map { "\($0.message)" }
                }
                let unfinishedWarning = allMessages.first {
                    $0.contains("Workflow finished while signal or update handlers are still running")
                }

                #expect(
                    unfinishedWarning == nil,
                    "Expected no unfinished handler warning when only .abandon update handlers are unfinished"
                )
            }
        }
    }
}
