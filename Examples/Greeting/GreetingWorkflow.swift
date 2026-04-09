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

@Workflow
struct GreetingWorkflow {
    mutating func run(context: WorkflowContext<Self>, input: String) async throws -> String {
        let greeting = try await context.executeActivity(
            GreetingActivities.Activities.SayHello.self,
            options: ActivityOptions(
                startToCloseTimeout: .seconds(30)
            ),
            input: input
        )

        return greeting
    }
}
