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

import Foundation
import Synchronization
import Temporal
import TemporalTestKit
import Testing

extension TestServerDependentTests {
    @Suite(.tags(.workflowTests))
    struct WorkflowStateTests {
        @Workflow
        final class StateWorkflow {
            struct Output: Codable {
                var counter1: Int
                var counter2: Int
                var counter3: Int?
            }
            private var counter1: Int
            private var counter2: Int = 0
            private var counter3: Int?

            init(input: Int) {
                self.counter1 = input
            }

            func run(input: Int) async throws -> Output {
                self.counter1 += 1
                self.counter2 += 1
                self.counter3? += 1

                await withTaskGroup { group in
                    group.addTask {
                        self.counter1 += 1
                        self.counter2 += 1
                        self.counter3? += 1
                    }
                    group.addTask {
                        self.counter1 += 1
                        self.counter2 += 1
                        self.counter3? += 1
                    }
                }

                return Output(
                    counter1: self.counter1,
                    counter2: self.counter2,
                    counter3: self.counter3
                )
            }
        }

        @Test
        func state() async throws {
            let result = try await executeWorkflow(
                StateWorkflow.self,
                input: 0
            )
            #expect(result.counter1 == 3)
            #expect(result.counter2 == 3)
            #expect(result.counter3 == nil)
        }
    }
}
