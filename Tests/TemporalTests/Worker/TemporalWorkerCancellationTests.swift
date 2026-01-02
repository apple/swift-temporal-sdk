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
import ServiceLifecycle
import Temporal
import Testing

extension TestServerDependentTests {
    @Suite
    struct TemporalWorkerCancellationTests {
        @Workflow
        final class SimpleWorkflow {
            func run(input: Void) async throws {
                try await Workflow.sleep(for: .seconds(1000))
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

        @Test
        func gracefullyShutdownWorker() async throws {
            struct ExecuteWorkflowService: Service {
                func run() async throws {
                    try await executeWorkflow(
                        SimpleWorkflow.self,
                        input: ()
                    )
                }
            }
            let serviceGroup = ServiceGroup(
                services: [ExecuteWorkflowService()],
                logger: Logger(label: "TestLogger")
            )
            await withThrowingTaskGroup { group in
                group.addTask {
                    try await serviceGroup.run()
                }
                await serviceGroup.triggerGracefulShutdown()

                await #expect(throws: (any Error).self) {
                    try await group.waitForAll()
                }
            }
        }
    }
}
