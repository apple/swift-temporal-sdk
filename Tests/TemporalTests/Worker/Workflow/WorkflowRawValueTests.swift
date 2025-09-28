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
import Logging
import Temporal
import TemporalTestKit
import Testing

extension TestServerDependentTests {
    @Suite(.tags(.workflowTests))
    struct WorkflowRawValueTests {
        @Workflow
        final class RawValueWorkflow {
            func run(input: TemporalRawValue) async throws -> TemporalRawValue {
                try await Workflow.executeActivity(
                    Container.Activities.DoubleContent.self,
                    options: .init(scheduleToCloseTimeout: .seconds(100)),
                    input: input
                )
            }
        }

        @ActivityContainer
        struct Container {
            @Activity
            static func doubleContent(input: TemporalRawValue) -> TemporalRawValue {
                let data = input.payload.data + input.payload.data
                let metadata = input.payload.metadata
                return .init(.init(data: data, metadata: metadata))
            }
        }

        @Test
        func rawValueWorkflow() async throws {
            let converter = JSONPayloadConverter()
            let payload = try converter.convertValue(5)
            let expected = try converter.convertValue(55)

            let result = try await executeWorkflow(
                RawValueWorkflow.self,
                input: .init(payload),
                activities: Container().allActivities
            )

            try #require(result.payload == expected)
        }
    }
}
