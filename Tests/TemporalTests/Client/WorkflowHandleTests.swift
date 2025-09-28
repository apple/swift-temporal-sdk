//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Temporal SDK open source project
//
// Copyright (c) 2025 Apple Inc. and the Swift Temporal SDK project authors
// Licensed under MIT License
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Swift Cassandra Client project authors
//
// SPDX-License-Identifier: MIT
//
//===----------------------------------------------------------------------===//

import Temporal
import TemporalTestKit
import Testing

extension TestServerDependentTests {
    @Suite(.tags(.clientTests))
    struct WorkflowHandleTests {
        @Workflow
        final class HelloWorldWorkflow {
            func run(input: Void) async -> String {
                "Hello, World!"
            }
        }

        @Workflow
        final class HelloInputWorkflow {
            func run(input: String) async -> String {
                input
            }
        }

        @Test
        func startWorkflowWithoutInput() async throws {
            try await workflowHandle(for: HelloWorldWorkflow.self, input: ()) { handle in
                let result = try await handle.result()
                #expect(result == "Hello, World!")
            }

            let result = try await workflowHandle(for: HelloWorldWorkflow.self, input: ()) { handle in
                try await handle.result()
            }
            #expect(result == "Hello, World!")
        }

        @Test
        func startWorkflowWithInput() async throws {
            let input = "Hello, Input!"

            try await workflowHandle(for: HelloInputWorkflow.self, input: input) { handle in
                let result = try await handle.result()
                #expect(result == input)
            }
        }
    }
}
