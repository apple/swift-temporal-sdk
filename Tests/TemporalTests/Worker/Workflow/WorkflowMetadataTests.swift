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

import Synchronization
import Temporal
import TemporalTestKit
import Testing

extension TestServerDependentTests {
    @Suite(.tags(.workflowTests))
    struct WorkflowMetadataTests {
        @Workflow
        struct TestWorkflow {
            mutating func run(context: WorkflowContext<Self>, input: Void) async throws {
                context.currentDetails = "initial current details"
                try await context.condition { $0.shouldContinue }
                context.currentDetails = "final current details"
            }

            @WorkflowSignal
            func someSignal(input: Void) {}

            @WorkflowSignal(name: "some signal", description: "some signal description")
            func someOtherSignal(input: Void) {}

            @WorkflowQuery(description: "continue description")
            func `continue`(input: Void) throws -> Bool {
                return shouldContinue
            }
            var shouldContinue = false

            @WorkflowUpdate(description: "some update description")
            mutating func someUpdate(context: WorkflowContext<Self>, input: Void) async throws {
                self.shouldContinue = true
            }

            @WorkflowUpdate(name: "some update")
            func someOtherUpdate(input: Void) async throws {}

            @WorkflowQuery(name: "__temporal_workflow_metadata")
            func workflowMetadata(input: Void) throws -> Api.Sdk.V1.WorkflowMetadata {
                throw TestError()
            }
        }

        @Test
        func hasCorrectValues() async throws {
            try await workflowHandle(
                for: TestWorkflow.self,
                input: ()
            ) { handle in
                try await expectWithRetry {
                    try await !handle.query(queryType: TestWorkflow.Continue.self)
                }

                let metadata = try await handle.query(queryType: TestWorkflow.WorkflowMetadata.self)
                #expect(metadata.currentDetails == "initial current details")
                #expect(metadata.definition.type == "TestWorkflow")

                let signals = metadata.definition.signalDefinitions
                #expect(signals.count == 2)
                #expect(signals.first { $0.name == "SomeSignal" }?.description_p == "")
                #expect(signals.first { $0.name == "some signal" }?.description_p == "some signal description")

                let queries = metadata.definition.queryDefinitions
                #expect(queries.count == 2)
                #expect(queries.first { $0.name == "Continue" }?.description_p == "continue description")
                #expect(queries.first { $0.name == "__temporal_workflow_metadata" }?.description_p == "")

                let updates = metadata.definition.updateDefinitions
                #expect(updates.count == 2)
                #expect(updates.first { $0.name == "SomeUpdate" }?.description_p == "some update description")
                #expect(updates.first { $0.name == "some update" }?.description_p == "")
            }
        }
    }
}
