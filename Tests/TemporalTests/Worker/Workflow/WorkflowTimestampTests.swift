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
import Temporal
import TemporalTestKit
import Testing

extension TestServerDependentTests {
    @Suite(.tags(.workflowTests))
    struct WorkflowTimestampTests {
        struct Result: Codable {
            let now0: Date
            let now1: Date
            let end: Date
        }

        @Workflow
        final class SlowWorkflow {
            func run(input: Void) async throws -> Result {
                let now0 = Workflow.now
                let now1 = Workflow.now

                try await Workflow.sleep(for: .seconds(1))
                let end = Workflow.now

                return Result(now0: now0, now1: now1, end: end)
            }

            @WorkflowQuery
            func queryTime(input: Void) -> Date {
                Workflow.now
            }
        }

        @Test
        func testWorkflowTimestamp() async throws {
            try await withTimeSkippingTestWorkerAndClient(workflows: [SlowWorkflow.self]) { taskQueue, client in
                let result = try await client.executeWorkflow(
                    type: SlowWorkflow.self,
                    options: .init(id: "wf-\(UUID().uuidString)", taskQueue: taskQueue)
                )

                #expect(result.now0 == result.now1)
                #expect(result.end > result.now1)
            }
        }

        @Test
        func workflowContextAccess() async throws {
            try await withTimeSkippingTestWorkerAndClient(workflows: [SlowWorkflow.self]) { taskQueue, client in
                let handle = try await client.startWorkflow(
                    type: SlowWorkflow.self,
                    options: .init(id: "wf-\(UUID().uuidString)", taskQueue: taskQueue)
                )

                let now = try await handle.query(queryType: SlowWorkflow.QueryTime.self)

                let result = try await handle.result()

                #expect(now >= result.now0)
                #expect(now < result.end)
            }
        }
    }
}
