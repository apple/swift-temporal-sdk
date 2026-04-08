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
    @Suite(.tags(.workflowTests))
    struct WorkflowMemoTests {
        @Workflow
        struct MemoWorkflow {
            struct Output: Codable, Hashable {
                var originalKey1: String?
                var originalKey2: String?
                var originalKey3: String?
                var updatedKey1: String?
                var updatedKey2: String?
                var updatedKey3: String?
            }

            mutating func run(context: WorkflowContext<Self>, input: Void) async throws -> Output {
                var output = Output()
                output.originalKey1 = try await context.getMemoValue(for: "key1")
                output.originalKey2 = try await context.getMemoValue(for: "key2")
                output.originalKey3 = try await context.getMemoValue(for: "key3")
                try await context.upsertMemo(["key1": "new-val1", "key2": nil])
                output.updatedKey1 = try await context.getMemoValue(for: "key1")
                output.updatedKey2 = try await context.getMemoValue(for: "key2")
                output.updatedKey3 = try await context.getMemoValue(for: "key3")
                return output
            }
        }

        @Test
        func memo() async throws {
            let result = try await executeWorkflow(
                MemoWorkflow.self,
                input: (),
                memo: ["key1": "val1", "key2": "val2", "key3": "val3"]
            )

            var expectedResult = MemoWorkflow.Output()
            expectedResult.originalKey1 = "val1"
            expectedResult.originalKey2 = "val2"
            expectedResult.originalKey3 = "val3"
            expectedResult.updatedKey1 = "new-val1"
            expectedResult.updatedKey3 = "val3"
            #expect(result == expectedResult)
        }
    }
}
