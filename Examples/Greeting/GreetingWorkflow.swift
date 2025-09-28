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

import Temporal

@Workflow
final class GreetingWorkflow {
    func run(input: String) async throws -> String {
        let greeting = try await Workflow.executeActivity(
            GreetingActivities.Activities.SayHello.self,
            options: ActivityOptions(
                startToCloseTimeout: .seconds(30)
            ),
            input: input
        )

        return greeting
    }
}
