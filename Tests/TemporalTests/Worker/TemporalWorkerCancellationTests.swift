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

import Logging
import Temporal
import Testing

extension TestServerDependentTests {
    @Suite
    struct TemporalWorkerCancellationTests {
        @Workflow
        struct SimpleWorkflow {
            mutating func run(context: WorkflowContext<Self>, input: Void) async throws {
                try await context.sleep(for: .seconds(1000))
            }
        }

        @Test
        func cancelWorker() async throws {
            await withThrowingTaskGroup { group in
                group.addTask {
                    try await executeWorkflow(
                        SimpleWorkflow.self,
                        input: ()
                    )
                }

                group.cancelAll()
                await #expect(throws: (any Error).self) {
                    try await group.next()
                }
            }
        }
    }
}
