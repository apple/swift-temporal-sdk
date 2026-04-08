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
import Temporal
import TemporalTestKit
import Testing

// MARK: - Test Suite

extension TestServerDependentTests {
    @Suite(.tags(.workflowTests))
    struct WorkflowReplayerTests {
        struct ReplayParams: Codable, Sendable {
            let name: String
            var shouldWait: Bool = false
            var shouldError: Bool = false
            var shouldCauseNonDeterminism: Bool = false
        }

        struct ReplayActivity: ActivityDefinition {
            static let name: String? = "ReplayActivity"

            func run(input name: String) async throws -> String {
                "Hello, \(name)!"
            }
        }

        @Workflow
        struct SayHelloWorkflow {
            private var waiting = false
            private var finish = false

            mutating func run(context: WorkflowContext<Self>, input params: ReplayParams) async throws -> String {
                let result = try await context.executeActivity(
                    ReplayActivity.self,
                    options: .init(scheduleToCloseTimeout: .seconds(60)),
                    input: params.name
                )

                // Wait if requested
                if params.shouldWait {
                    self.waiting = true
                    try await context.condition { $0.finish }
                    self.waiting = false
                }

                // Throw if requested
                if params.shouldError {
                    throw ApplicationError(message: "Intentional error")
                }

                // Cause non-determinism if requested and we're replaying
                // This simulates a code change that adds an extra timer
                if params.shouldCauseNonDeterminism && context.isReplaying {
                    try await context.sleep(for: .milliseconds(1))
                }

                return result
            }

            @WorkflowSignal
            mutating func finish(input: Void) async {
                finish = true
            }

            @WorkflowQuery
            func waiting(input: Void) -> Bool {
                waiting
            }
        }

        // MARK: - Simple Replay Tests

        @Test
        func replaySimpleWorkflowSucceeds() async throws {
            try await withTestWorkerAndClient(
                activities: [ReplayActivity()],
                workflows: [SayHelloWorkflow.self]
            ) { taskQueue, client in
                let params = ReplayParams(name: "Temporal")
                let workflowID = "replayer-test-simple-\(UUID().uuidString)"
                let handle = try await client.startWorkflow(
                    type: SayHelloWorkflow.self,
                    options: .init(id: workflowID, taskQueue: taskQueue),
                    input: params
                )
                let result = try await handle.result()
                #expect(result == "Hello, Temporal!")

                let history = try await handle.fetchHistory()

                var config = WorkflowReplayer.Configuration()
                config.workflows.append(SayHelloWorkflow.self)
                let replayer = WorkflowReplayer(configuration: config)

                let replayResult = try await replayer.replayWorkflow(history: history)
                #expect(replayResult.replayFailure == nil)
            }
        }

        @Test
        func replayFailedWorkflowSucceeds() async throws {
            try await withTestWorkerAndClient(
                activities: [ReplayActivity()],
                workflows: [SayHelloWorkflow.self]
            ) { taskQueue, client in
                let params = ReplayParams(name: "Temporal", shouldError: true)
                let workflowID = "replayer-test-failed-\(UUID().uuidString)"
                let handle = try await client.startWorkflow(
                    type: SayHelloWorkflow.self,
                    options: .init(id: workflowID, taskQueue: taskQueue),
                    input: params
                )

                await #expect(throws: WorkflowFailedError.self) {
                    try await handle.result()
                }

                let history = try await handle.fetchHistory()

                var config = WorkflowReplayer.Configuration()
                config.workflows.append(SayHelloWorkflow.self)
                let replayer = WorkflowReplayer(configuration: config)

                let replayResult = try await replayer.replayWorkflow(history: history)
                #expect(replayResult.replayFailure == nil)
            }
        }

        // MARK: - Non-determinism Detection Tests

        @Test
        func replayNondeterministicWorkflowFails() async throws {
            try await withTestWorkerAndClient(
                activities: [ReplayActivity()],
                workflows: [SayHelloWorkflow.self]
            ) { taskQueue, client in
                // Run workflow WITH non-determinism flag set
                // During initial execution, isReplaying is false, so no extra timer
                let params = ReplayParams(name: "Temporal", shouldCauseNonDeterminism: true)
                let workflowID = "replayer-test-nondet-\(UUID().uuidString)"
                let handle = try await client.startWorkflow(
                    type: SayHelloWorkflow.self,
                    options: .init(id: workflowID, taskQueue: taskQueue),
                    input: params
                )
                _ = try await handle.result()

                let history = try await handle.fetchHistory()

                // Replay the same workflow with same params
                // Now isReplaying is true, so the extra timer WILL be added
                // This causes non-determinism with the captured history
                var config = WorkflowReplayer.Configuration()
                config.workflows.append(SayHelloWorkflow.self)
                let replayer = WorkflowReplayer(configuration: config)

                await #expect(throws: WorkflowNondeterminismError.self) {
                    try await replayer.replayWorkflow(history: history)
                }
            }
        }

        @Test
        func replayNondeterministicWithoutThrowingReturnsFailure() async throws {
            try await withTestWorkerAndClient(
                activities: [ReplayActivity()],
                workflows: [SayHelloWorkflow.self]
            ) { taskQueue, client in
                // Run workflow WITH non-determinism flag set
                let params = ReplayParams(name: "Temporal", shouldCauseNonDeterminism: true)
                let workflowID = "replayer-test-nondet-nothrow-\(UUID().uuidString)"
                let handle = try await client.startWorkflow(
                    type: SayHelloWorkflow.self,
                    options: .init(id: workflowID, taskQueue: taskQueue),
                    input: params
                )
                _ = try await handle.result()

                let history = try await handle.fetchHistory()

                var config = WorkflowReplayer.Configuration()
                config.workflows.append(SayHelloWorkflow.self)
                let replayer = WorkflowReplayer(configuration: config)

                let replayResult = try await replayer.replayWorkflow(
                    history: history,
                    throwOnReplayFailure: false
                )

                #expect(replayResult.replayFailure != nil)
                #expect(replayResult.replayFailure is WorkflowNondeterminismError)
            }
        }

        // MARK: - JSON History Tests

        @Test
        func replayFromInvalidJSONThrowsError() async throws {
            var config = WorkflowReplayer.Configuration()
            config.workflows.append(SayHelloWorkflow.self)
            let replayer = WorkflowReplayer(configuration: config)

            await #expect(throws: (any Error).self) {
                _ = try await replayer.replayWorkflow(
                    history: .fromJSON(
                        workflowID: "test",
                        jsonData: Data("not valid json".utf8)
                    )
                )
            }
        }

        @Test
        func replayIncompleteWorkflowSucceeds() async throws {
            try await withTestWorkerAndClient(
                activities: [ReplayActivity()],
                workflows: [SayHelloWorkflow.self]
            ) { taskQueue, client in
                // Start workflow with shouldWait flag - it will wait on a signal
                let params = ReplayParams(name: "Temporal", shouldWait: true)
                let workflowID = "replayer-test-incomplete-\(UUID().uuidString)"
                let handle = try await client.startWorkflow(
                    type: SayHelloWorkflow.self,
                    options: .init(id: workflowID, taskQueue: taskQueue),
                    input: params
                )

                // Wait until workflow reaches waiting state
                while true {
                    let waiting = try await handle.query(
                        queryType: SayHelloWorkflow.Waiting.self
                    )
                    if waiting {
                        break
                    } else {
                        try await Task.sleep(for: .seconds(0.1))
                    }
                }

                // Fetch incomplete history and replay it
                let history = try await handle.fetchHistory()

                var config = WorkflowReplayer.Configuration()
                config.workflows.append(SayHelloWorkflow.self)
                let replayer = WorkflowReplayer(configuration: config)

                let replayResult = try await replayer.replayWorkflow(history: history)
                #expect(replayResult.replayFailure == nil)
            }
        }

        @Test
        func replayFromCompleteJSONFileSucceeds() async throws {
            let testBundle = Bundle.module
            guard
                let jsonURL = testBundle.url(
                    forResource: "replayer-test.complete",
                    withExtension: "json",
                    subdirectory: "Histories"
                )
            else {
                Issue.record("Failed to find replayer-test.complete.json in test bundle")
                return
            }

            let jsonData = try Data(contentsOf: jsonURL)

            var config = WorkflowReplayer.Configuration()
            config.workflows.append(SayHelloWorkflow.self)
            let replayer = WorkflowReplayer(configuration: config)

            let result = try await replayer.replayWorkflow(
                history: .fromJSON(
                    workflowID: "test-workflow-id",
                    jsonData: jsonData,
                )
            )

            #expect(result.replayFailure == nil)
        }

        @Test
        func replayFromNondeterministicJSONFileFails() async throws {
            let testBundle = Bundle.module
            guard
                let jsonURL = testBundle.url(
                    forResource: "replayer-test.nondeterministic",
                    withExtension: "json",
                    subdirectory: "Histories"
                )
            else {
                Issue.record("Failed to find replayer-test.nondeterministic.json in test bundle")
                return
            }

            let jsonData = try Data(contentsOf: jsonURL)

            var config = WorkflowReplayer.Configuration()
            config.workflows.append(SayHelloWorkflow.self)
            let replayer = WorkflowReplayer(configuration: config)

            // Test that it throws when throwOnReplayFailure is true
            await #expect(throws: WorkflowNondeterminismError.self) {
                _ =
                    try await replayer
                    .replayWorkflow(
                        history: .fromJSON(
                            workflowID: "test-workflow-id",
                            jsonData: jsonData,
                        )
                    )
            }

            // Test that it returns failure when throwOnReplayFailure is false
            let result = try await replayer.replayWorkflow(
                history: .fromJSON(
                    workflowID: "test-workflow-id",
                    jsonData: jsonData,
                ),
                throwOnReplayFailure: false
            )

            #expect(result.replayFailure != nil)
            #expect(result.replayFailure is WorkflowNondeterminismError)
        }

        // MARK: - Multiple Workflow Tests

        @Test
        func replayMultipleWorkflowsCollectsAllResults() async throws {
            try await withTestWorkerAndClient(
                activities: [ReplayActivity()],
                workflows: [SayHelloWorkflow.self]
            ) { taskQueue, client in
                let params1 = ReplayParams(name: "First")
                let params2 = ReplayParams(name: "Second")

                let handle1 = try await client.startWorkflow(
                    type: SayHelloWorkflow.self,
                    options: .init(
                        id: "replayer-multi-1-\(UUID().uuidString)",
                        taskQueue: taskQueue
                    ),
                    input: params1
                )
                let handle2 = try await client.startWorkflow(
                    type: SayHelloWorkflow.self,
                    options: .init(
                        id: "replayer-multi-2-\(UUID().uuidString)",
                        taskQueue: taskQueue
                    ),
                    input: params2
                )

                _ = try await handle1.result()
                _ = try await handle2.result()

                let history1 = try await handle1.fetchHistory()
                let history2 = try await handle2.fetchHistory()

                var config = WorkflowReplayer.Configuration()
                config.workflows.append(SayHelloWorkflow.self)
                let replayer = WorkflowReplayer(configuration: config)

                let results = try await replayer.replayWorkflows(
                    histories: [history1, history2],
                    throwOnReplayFailure: false
                )

                #expect(results.count == 2)
            }
        }

        @Test
        func replayMultipleWorkflowsThrowsOnFirstFailure() async throws {
            try await withTestWorkerAndClient(
                activities: [ReplayActivity()],
                workflows: [SayHelloWorkflow.self]
            ) { taskQueue, client in
                // Run workflow with non-determinism flag
                let params = ReplayParams(name: "Test", shouldCauseNonDeterminism: true)

                let handle = try await client.startWorkflow(
                    type: SayHelloWorkflow.self,
                    options: .init(
                        id: "replayer-multi-fail-\(UUID().uuidString)",
                        taskQueue: taskQueue
                    ),
                    input: params
                )

                _ = try await handle.result()
                let history = try await handle.fetchHistory()

                var config = WorkflowReplayer.Configuration()
                config.workflows.append(SayHelloWorkflow.self)
                let replayer = WorkflowReplayer(configuration: config)

                // Replay should detect non-determinism and throw on first failure
                await #expect(throws: WorkflowNondeterminismError.self) {
                    _ = try await replayer.replayWorkflows(
                        histories: [history, history],
                        throwOnReplayFailure: true
                    )
                }
            }
        }
    }
}
