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

/// Child workflow that makes a single pizza.
///
/// Demonstrates a typical child workflow with multiple activities.
@Workflow
final class MakePizzaWorkflow {
    // MARK: - Input/Output Types

    struct PizzaInput: Codable {
        let pizzaNumber: Int
        let size: String
        let toppings: [String]
    }

    // MARK: - Workflow Implementation

    func run(input: PizzaInput) async throws -> String {
        // Step 1: Prepare the dough
        _ = try await Workflow.executeActivity(
            PizzaActivities.Activities.PrepareDough.self,
            options: .init(startToCloseTimeout: .seconds(30)),
            input: PizzaActivities.PrepareDoughInput(size: input.size)
        )

        // Step 2: Add toppings
        _ = try await Workflow.executeActivity(
            PizzaActivities.Activities.AddToppings.self,
            options: .init(startToCloseTimeout: .seconds(30)),
            input: PizzaActivities.AddToppingsInput(
                toppings: input.toppings,
                size: input.size
            )
        )

        // Step 3: Bake the pizza
        let bakeResult = try await Workflow.executeActivity(
            PizzaActivities.Activities.BakePizza.self,
            options: .init(startToCloseTimeout: .seconds(30)),
            input: PizzaActivities.BakePizzaInput(
                size: input.size,
                toppings: input.toppings
            )
        )

        return "Pizza #\(input.pizzaNumber) (\(input.size), \(input.toppings.joined(separator: ", "))) - \(bakeResult)"
    }
}
