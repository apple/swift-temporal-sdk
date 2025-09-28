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
    struct UnregisteredWorkflowSleepTests {
        @Test
        func unregistered() async throws {
            try await withTestWorkerAndClient { taskQueue, client in
                _ = try await client.workflowService.startWorkflow(
                    name: "Unregistered",
                    options: .init(
                        id: UUID().uuidString,
                        taskQueue: taskQueue
                    ),
                    headers: [:],
                    input: ()
                )
            }
        }
    }
}
