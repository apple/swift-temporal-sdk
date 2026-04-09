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
import Temporal
import TemporalTestKit
import Testing

extension TestServerDependentTests {
    @Suite(.tags(.workflowTests))
    struct TimeSkippingInterceptorTests {
        @Workflow
        struct LongTimerWorkflow {
            mutating func run(context: WorkflowContext<Self>, input: Void) async throws -> String {
                // Sleep for 1 hour in workflow time
                try await context.sleep(for: .seconds(3600))
                return "completed"
            }
        }

        @Test
        func longTimerCompletesQuicklyWithTimeSkipping() async throws {
            let start = ContinuousClock.now
            try await withTimeSkippingTestWorkerAndClient(
                workflows: [LongTimerWorkflow.self]
            ) { taskQueue, client in
                let handle = try await client.startWorkflow(
                    type: LongTimerWorkflow.self,
                    options: .init(id: "time-skip-\(UUID())", taskQueue: taskQueue)
                )
                let result = try await handle.result()
                #expect(result == "completed")
            }
            let elapsed = ContinuousClock.now - start
            // The 1-hour timer should complete well under 60 seconds of wall clock time
            #expect(elapsed < .seconds(60))
        }

        @Test
        func currentTimeReturnsValue() async throws {
            let testServer = TemporalTestServer.timeSkippingTestServer!
            let time = try await testServer.currentTime()
            // The time should be a reasonable date (after 2020)
            let referenceDate = Date(timeIntervalSince1970: 1_577_836_800)  // 2020-01-01
            #expect(time > referenceDate)
        }

        @Test
        func sleepAdvancesTime() async throws {
            let testServer = TemporalTestServer.timeSkippingTestServer!
            let timeBefore = try await testServer.currentTime()
            try await testServer.sleep(.seconds(3600))
            let timeAfter = try await testServer.currentTime()
            // Time should have advanced by at least 1 hour
            let elapsed = timeAfter.timeIntervalSince(timeBefore)
            #expect(elapsed >= 3599)
        }
    }
}
