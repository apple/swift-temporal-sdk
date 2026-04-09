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
    struct WorkflowHistoryInfoTests {
        @Workflow
        struct HistoryInfoWorkflow {
            struct Output: Codable {
                let isReplaying: Bool
                let continueAsNewSuggested: Bool
                let currentHistoryLength: Int
                let currentHistorySize: Int
            }

            mutating func run(context: WorkflowContext<Self>, input: Void) async throws -> Output {
                try await withThrowingDiscardingTaskGroup { group in
                    for _ in 0..<30 {
                        group.addTask {
                            try await context.sleep(for: .milliseconds(10))
                        }
                    }
                }

                return .init(
                    isReplaying: context.isReplaying,
                    continueAsNewSuggested: context.continueAsNewSuggested,
                    currentHistoryLength: context.currentHistoryLength,
                    currentHistorySize: context.currentHistorySize
                )
            }
        }

        @Test
        func historyInfo() async throws {
            let info = try await executeWorkflow(
                HistoryInfoWorkflow.self,
                input: ()
            )

            #expect(!info.isReplaying)
            #expect(!info.continueAsNewSuggested)
            #expect(info.currentHistoryLength > 60)
            #expect(info.currentHistorySize > 1500)
        }
    }
}
