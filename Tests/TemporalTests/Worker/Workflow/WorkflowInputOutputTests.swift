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
    struct WorkflowInputOutputTests {
        @Workflow
        struct VoidWorkflow {
            mutating func run(context: WorkflowContext<Self>, input: Void) async {}
        }

        @Workflow
        struct StringWorkflow {
            mutating func run(context: WorkflowContext<Self>, input: String) async -> String {
                return input
            }
        }

        @Workflow
        struct TestStructWorkflow {
            struct TestStruct {}

            mutating func run(context: WorkflowContext<Self>, input: Void) async -> TestStruct {
                return .init()
            }
        }

        static let throwsTestErrorThenSucceedsCounter = Mutex(0)
        @Workflow
        struct ThrowingWorkflow {
            enum Scenario: Codable {
                case throwTestError
                case throwApplicationError
                case throwsTestErrorThenSucceeds
            }

            mutating func run(context: WorkflowContext<Self>, input: Scenario) async throws {
                switch input {
                case .throwTestError:
                    throw TestError()
                case .throwApplicationError:
                    throw ApplicationError(
                        message: "CustomApplicationError",
                        type: "Failure"
                    )
                case .throwsTestErrorThenSucceeds:
                    if throwsTestErrorThenSucceedsCounter.withLock({ $0 == 0 }) {
                        throwsTestErrorThenSucceedsCounter.withLock({ $0 += 1 })
                        throw TestError()
                    }
                }
            }
        }

        @Test
        func void() async throws {
            try await executeWorkflow(
                VoidWorkflow.self,
                input: ()
            )
        }

        @Test
        func string() async throws {
            let result = try await executeWorkflow(
                StringWorkflow.self,
                input: "Hello"
            )

            #expect(result == "Hello")
        }

        @Test
        func testStruct() async throws {
            await #expect(throws: WorkflowFailedError.self) {
                _ = try await executeWorkflow(
                    TestStructWorkflow.self,
                    input: (),
                    workflowExecutionTimeout: .seconds(1)
                )
            }
        }

        @Test
        func throwsTestError() async throws {
            await #expect(throws: WorkflowFailedError.self) {
                _ = try await executeWorkflow(
                    ThrowingWorkflow.self,
                    input: .throwTestError,
                    workflowExecutionTimeout: .seconds(1)
                )
            }
        }

        @Test
        func throwsApplicationError() async throws {
            await #expect(throws: WorkflowFailedError.self) {
                _ = try await executeWorkflow(
                    ThrowingWorkflow.self,
                    input: .throwApplicationError
                )
            }
        }

        @Test
        func throwsTestErrorThenSucceeds() async throws {
            _ = try await executeWorkflow(
                ThrowingWorkflow.self,
                input: .throwsTestErrorThenSucceeds
            )
        }
    }
}
