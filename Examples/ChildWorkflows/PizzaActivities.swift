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

/// Activities for pizza restaurant operations.
@ActivityContainer
struct PizzaActivities {
    // MARK: - Activity Input Types

    struct PrepareDoughInput: Codable {
        let size: String
    }

    struct AddToppingsInput: Codable {
        let toppings: [String]
        let size: String
    }

    struct BakePizzaInput: Codable {
        let size: String
        let toppings: [String]
    }

    struct PrepareSidesInput: Codable {
        let sides: [String]
    }

    struct AssignDriverInput: Codable {
        let orderId: String
        let address: String
        let itemCount: Int
    }

    struct AssignDriverOutput: Codable {
        let driverName: String
        let driverNumber: Int
        let estimatedMinutes: Int
    }

    struct DeliverOrderInput: Codable {
        let orderId: String
        let driverName: String
        let address: String
        let phone: String
    }

    // MARK: - Pizza Making Activities

    /// Prepares pizza dough.
    @Activity
    func prepareDough(input: PrepareDoughInput) async throws -> String {
        let prepTime: Int
        switch input.size.lowercased() {
        case "small": prepTime = 2
        case "medium": prepTime = 3
        case "large": prepTime = 4
        default: prepTime = 3
        }

        try await Task.sleep(for: .seconds(Double(prepTime)))
        return "dough ready"
    }

    /// Adds toppings to pizza.
    @Activity
    func addToppings(input: AddToppingsInput) async throws -> String {
        let toppingTime = input.toppings.count
        try await Task.sleep(for: .seconds(Double(toppingTime)))
        return "\(input.toppings.count) toppings added"
    }

    /// Bakes the pizza.
    @Activity
    func bakePizza(input: BakePizzaInput) async throws -> String {
        let bakeTime: Int
        switch input.size.lowercased() {
        case "small": bakeTime = 8
        case "medium": bakeTime = 10
        case "large": bakeTime = 12
        default: bakeTime = 10
        }

        try await Task.sleep(for: .seconds(Double(bakeTime)))
        return "ready"
    }

    // MARK: - Sides Activities

    /// Prepares side items.
    @Activity
    func prepareSides(input: PrepareSidesInput) async throws -> String {
        let prepTime = input.sides.count * 3
        try await Task.sleep(for: .seconds(Double(prepTime)))
        return "ready"
    }

    // MARK: - Delivery Activities

    /// Assigns a driver to the delivery.
    @Activity
    func assignDriver(input: AssignDriverInput) async throws -> AssignDriverOutput {
        try await Task.sleep(for: .seconds(2))

        let drivers = ["Sarah", "Mike", "Jessica", "David", "Emma"]
        let driverIndex = abs(input.orderId.hashValue) % drivers.count
        let driverName = drivers[driverIndex]
        let driverNumber = (driverIndex + 1) * 10 + Int.random(in: 1...9)

        // Estimate delivery time based on item count
        let estimatedMinutes = 20 + (input.itemCount * 2)

        return AssignDriverOutput(
            driverName: driverName,
            driverNumber: driverNumber,
            estimatedMinutes: estimatedMinutes
        )
    }

    /// Delivers the order.
    @Activity
    func deliverOrder(input: DeliverOrderInput) async throws -> String {
        try await Task.sleep(for: .seconds(3))
        return "delivered to \(input.address)"
    }
}
