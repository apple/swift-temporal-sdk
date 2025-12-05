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

import Foundation
import Logging
import Synchronization
import Temporal
import Testing

// Mock bridge worker for testing
private final class MockBridgeWorker: BridgeWorkerProtocol {
    init() {}

    init(client: borrowing Temporal.BridgeClient, configuration: Temporal.TemporalWorker.Configuration) throws {
        fatalError("Not implemented for workflow worker tests")
    }

    deinit {}
    func initiateShutdown() {}
    func finalizeShutdown() async throws {}
    func pollWorkflowActivation() async throws -> Coresdk_WorkflowActivation_WorkflowActivation { fatalError() }
    func completeWorkflowActivation(completion: Coresdk_WorkflowCompletion_WorkflowActivationCompletion) async throws { fatalError() }
    func pollActivityTask() async throws -> Coresdk_ActivityTask_ActivityTask { fatalError() }
    func completeActivityTask(_ completion: Coresdk_ActivityTaskCompletion) async throws { fatalError() }
    func recordActivityHeartbeat(_ heartbeat: Coresdk_ActivityHeartbeat) throws { fatalError() }
}

// Test workflows with duplicate names
private struct FirstWorkflow: WorkflowDefinition {
    static let name: String = "DuplicateWorkflow"

    init(input: Void) {}
    func run(input: Void) async throws {}
}

private struct SecondWorkflow: WorkflowDefinition {
    static let name: String = "DuplicateWorkflow"  // Same name as FirstWorkflow

    init(input: Void) {}
    func run(input: Void) async throws {}
}

private struct UniqueWorkflow: WorkflowDefinition {
    static let name: String = "UniqueWorkflow"

    init(input: Void) {}
    func run(input: Void) async throws {}
}

@Suite()
struct WorkflowWorkerTests {

    @Test
    func duplicateWorkflowRegistrationThrowsError() async throws {
        // Test that duplicate workflow registrations throw error
        let logHandler = InMemoryLogHandler()
        logHandler.logLevel = .trace  // Capture all logs including info
        let logger = Logger(label: "TestWorkflowWorker") { _ in logHandler }

        let bridgeWorker = MockBridgeWorker()
        let configuration = TemporalWorker.Configuration(
            namespace: "test-namespace",
            taskQueue: "test-queue",
            instrumentation: TemporalWorker.Configuration.Instrumentation(serverHostname: "localhost")
        )

        // Expect error to be thrown when creating WorkflowWorker with duplicate workflow names
        #expect(throws: (any Error).self) {
            let _ = try WorkflowWorker(
                worker: bridgeWorker,
                configuration: configuration,
                workflows: [FirstWorkflow.self, SecondWorkflow.self, UniqueWorkflow.self],
                logger: logger
            )
        }

        // Verify the info log was recorded before the error was thrown
        try logHandler.entries.withLock { entries in
            let infoEntries = entries.filter { $0.level == .info }
            #expect(infoEntries.count == 1)

            let logEntry = try #require(infoEntries.first)
            #expect(logEntry.message == "Duplicate workflow registration")

            // Verify structured metadata using workflow type key
            let workflowType = try #require(logEntry.metadata?["workflow.type"])
            #expect(workflowType == "DuplicateWorkflow")
        }
    }

    @Test
    func noDuplicateWorkflowsNoError() async throws {
        // Test that no duplicates means no errors and no logs
        let logHandler = InMemoryLogHandler()
        let logger = Logger(label: "TestWorkflowWorker") { _ in logHandler }

        let bridgeWorker = MockBridgeWorker()
        let configuration = TemporalWorker.Configuration(
            namespace: "test-namespace",
            taskQueue: "test-queue",
            instrumentation: TemporalWorker.Configuration.Instrumentation(serverHostname: "localhost")
        )

        // Should not throw when creating WorkflowWorker with unique workflow names
        let _ = try WorkflowWorker(
            worker: bridgeWorker,
            configuration: configuration,
            workflows: [UniqueWorkflow.self],
            logger: logger
        )

        // Verify no logs were recorded
        logHandler.entries.withLock { entries in
            #expect(entries.isEmpty)
        }
    }
}
