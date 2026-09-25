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
    struct WorkflowLoggerTests {
        /// Records the run ID found in the task local logger's metadata for every workflow entry point.
        @Workflow
        struct TaskLocalLoggerWorkflow {
            struct Observations: Codable, Hashable {
                var expectedRunID: String?
                var run: String?
                var signal: String?
                var validator: String?
                var update: String?
                var query: String?
            }

            static let validatorObservations = Mutex<[String: String]>([:])

            private var observations = Observations()
            private var finished = false

            static func taskLocalRunID() -> String? {
                Logger.current[metadataKey: TemporalTracingKeys.workflowRunId]?.description
            }

            mutating func run(context: WorkflowContext<Self>, input: Void) async throws {
                self.observations.expectedRunID = context.info.runID
                self.observations.run = Self.taskLocalRunID()
                try await context.condition { $0.finished }
            }

            @WorkflowSignal
            mutating func signal(input: Void) {
                self.observations.signal = Self.taskLocalRunID()
            }

            @WorkflowUpdate(validator: "validateUpdate")
            mutating func update(input: Void) async throws {
                // The validator ran just before us so its observation is available.
                if let expectedRunID = self.observations.expectedRunID {
                    self.observations.validator = Self.validatorObservations.withLock { $0[expectedRunID] }
                }
                self.observations.update = Self.taskLocalRunID()
            }

            func validateUpdate(input: Void) throws {
                guard let expectedRunID = self.observations.expectedRunID else { return }
                let observed = Self.taskLocalRunID()
                // Validators can't mutate workflow state so they record their observation here, keyed by run ID.
                Self.validatorObservations.withLock { $0[expectedRunID] = observed }
            }

            @WorkflowQuery
            func query(input: Void) throws -> Observations {
                var observations = self.observations
                observations.query = Self.taskLocalRunID()
                return observations
            }

            @WorkflowSignal
            mutating func finish(input: Void) {
                self.finished = true
            }
        }

        @Test
        func workflowEntryPointsSeeTheirOwnTaskLocalLogger() async throws {
            try await withTestWorkerAndClient(
                workflows: [TaskLocalLoggerWorkflow.self]
            ) { taskQueue, client in
                // Two workflows on the same worker so a leaked logger would show a mismatched run ID.
                let handles = [
                    try await client.startWorkflow(
                        type: TaskLocalLoggerWorkflow.self,
                        options: .init(id: UUID().uuidString, taskQueue: taskQueue)
                    ),
                    try await client.startWorkflow(
                        type: TaskLocalLoggerWorkflow.self,
                        options: .init(id: UUID().uuidString, taskQueue: taskQueue)
                    ),
                ]

                for handle in handles {
                    try await handle.signal(signalType: TaskLocalLoggerWorkflow.Signal.self)
                }
                for handle in handles {
                    try await handle.executeUpdate(updateType: TaskLocalLoggerWorkflow.Update.self, input: ())
                }

                for handle in handles {
                    let observations = try await handle.query(queryType: TaskLocalLoggerWorkflow.Query.self)
                    let expectedRunID = try #require(observations.expectedRunID)
                    #expect(observations.run == expectedRunID)
                    #expect(observations.signal == expectedRunID)
                    #expect(observations.validator == expectedRunID)
                    #expect(observations.update == expectedRunID)
                    #expect(observations.query == expectedRunID)
                }

                for handle in handles {
                    try await handle.signal(signalType: TaskLocalLoggerWorkflow.Finish.self)
                    try await handle.result()
                }
            }
        }
    }
}
