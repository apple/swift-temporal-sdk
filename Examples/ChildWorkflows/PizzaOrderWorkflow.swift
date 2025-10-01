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

/// Parent workflow that orchestrates pizza order fulfillment.
/// Demonstrates parallel and sequential child workflow execution.
@Workflow
final class PizzaOrderWorkflow {
    // MARK: - Input/Output Types

    struct OrderInput: Codable {
        let orderId: String
        let pizzas: [PizzaSpec]
        let sides: [String]
        let deliveryAddress: String
        let customerPhone: String
    }

    struct PizzaSpec: Codable {
        let size: String
        let toppings: [String]
    }

    struct OrderOutput: Codable {
        let orderId: String
        let pizzaResults: [String]
        let sidesResult: String
        let deliveryResult: String
        let totalTime: String
    }

    private let orderId: String

    init(input: OrderInput) {
        self.orderId = input.orderId
    }

    // MARK: - Workflow Implementation

    func run(input: OrderInput) async throws -> OrderOutput {
        let startTime = Workflow.now

        print("📦 Order \(input.orderId) - Starting fulfillment")
        print("   \(input.pizzas.count) pizza(s), sides: \(input.sides.joined(separator: ", "))")

        // Stage 1: Prepare pizzas and sides in parallel
        print("\n🍕 Stage 1: Kitchen preparation (parallel execution)")

        // Execute multiple pizza child workflows in parallel
        let pizzaResults = try await withThrowingTaskGroup(of: (Int, String).self) { group in
            for (index, pizzaSpec) in input.pizzas.enumerated() {
                group.addTask {
                    let handle = try await Workflow.startChildWorkflow(
                        MakePizzaWorkflow.self,
                        options: .init(id: "\(input.orderId)-pizza-\(index + 1)"),
                        input: MakePizzaWorkflow.PizzaInput(
                            pizzaNumber: index + 1,
                            size: pizzaSpec.size,
                            toppings: pizzaSpec.toppings
                        )
                    )
                    let result = try await handle.result()
                    return (index, result)
                }
            }

            var results: [String] = Array(repeating: "", count: input.pizzas.count)
            for try await (index, result) in group {
                results[index] = result
                print("   ✓ \(result)")
            }
            return results
        }

        // Execute sides preparation in parallel with pizzas (if any)
        let sidesResult: String
        if !input.sides.isEmpty {
            let sidesHandle = try await Workflow.startChildWorkflow(
                PrepareSidesWorkflow.self,
                options: .init(id: "\(input.orderId)-sides"),
                input: PrepareSidesWorkflow.SidesInput(sides: input.sides)
            )
            sidesResult = try await sidesHandle.result()
            print("   ✓ \(sidesResult)")
        } else {
            sidesResult = "No sides ordered"
        }

        print("   Kitchen preparation complete!")

        // Stage 2: Package everything
        print("\n📦 Stage 2: Packaging order")
        try await Workflow.sleep(for: .seconds(2))
        print("   ✓ Order packaged and ready for delivery")

        // Stage 3: Assign delivery (sequential - must happen after cooking)
        print("\n🚗 Stage 3: Delivery assignment (sequential execution)")
        let deliveryHandle = try await Workflow.startChildWorkflow(
            AssignDeliveryWorkflow.self,
            options: .init(id: "\(input.orderId)-delivery"),
            input: AssignDeliveryWorkflow.DeliveryInput(
                orderId: input.orderId,
                address: input.deliveryAddress,
                phone: input.customerPhone,
                itemCount: input.pizzas.count + (input.sides.isEmpty ? 0 : 1)
            )
        )
        let deliveryResult = try await deliveryHandle.result()
        print("   ✓ \(deliveryResult)")

        let endTime = Workflow.now
        let totalMinutes = Int(endTime.timeIntervalSince(startTime) / 60)

        return OrderOutput(
            orderId: input.orderId,
            pizzaResults: pizzaResults,
            sidesResult: sidesResult,
            deliveryResult: deliveryResult,
            totalTime: "\(totalMinutes) minutes"
        )
    }
}
