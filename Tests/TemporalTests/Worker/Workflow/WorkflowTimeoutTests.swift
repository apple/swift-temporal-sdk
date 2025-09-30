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

import Temporal
import TemporalTestKit
import Testing

extension TestServerDependentTests {
    @Suite(.tags(.workflowTests), .serialized)
    struct WorkflowTimeoutTests {
        @Workflow
        final class TimeoutWorkflow {
            enum Scenario: Codable {
                case timeoutSleep
                case errorIsRethrown
                case bodyReturnsAfterCancel
                case bodyReturnsBeforeCancel
                case alreadyCancelled
            }

            func run(input: Scenario) async throws -> String {
                switch input {
                case .timeoutSleep:
                    do {
                        try await Workflow.timeout(for: .seconds(1)) {
                            try await Workflow.sleep(for: .seconds(100))
                        }
                        return "Done"
                    } catch {
                        return "\(type(of: error))"
                    }
                case .errorIsRethrown:
                    do {
                        try await Workflow.timeout(for: .milliseconds(1)) {
                            throw TestError()
                        }
                        return "Done"
                    } catch {
                        return "\(type(of: error))"
                    }
                case .bodyReturnsAfterCancel:
                    return await Workflow.timeout(for: .milliseconds(1)) {
                        do {
                            try await Workflow.sleep(for: .seconds(100))
                            fatalError()
                        } catch {
                            return "Done"
                        }
                    }
                case .bodyReturnsBeforeCancel:
                    return await Workflow.timeout(for: .milliseconds(1)) {
                        return "Done"
                    }
                case .alreadyCancelled:
                    return await withTaskGroup(of: String.self) { group in
                        group.addTask {
                            await Workflow.timeout(for: .seconds(1)) {
                                return "Done"
                            }
                        }

                        group.cancelAll()
                        return await group.next()!
                    }
                }
            }
        }

        @Test(arguments: [
            (TimeoutWorkflow.Scenario.timeoutSleep, "CanceledError"),
            (TimeoutWorkflow.Scenario.errorIsRethrown, "TestError"),
            (TimeoutWorkflow.Scenario.bodyReturnsAfterCancel, "Done"),
            (TimeoutWorkflow.Scenario.bodyReturnsBeforeCancel, "Done"),
            (TimeoutWorkflow.Scenario.alreadyCancelled, "Done"),
        ])
        func sleep(scenario: TimeoutWorkflow.Scenario, expectedResult: String) async throws {
            let result = try await executeWorkflow(
                TimeoutWorkflow.self,
                input: scenario
            )

            #expect(result == expectedResult)
        }
    }
}
