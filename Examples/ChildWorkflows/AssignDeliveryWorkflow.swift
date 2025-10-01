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

/// Child workflow that handles delivery assignment and execution.
/// Runs sequentially after cooking is complete.
@Workflow
final class AssignDeliveryWorkflow {
    // MARK: - Input/Output Types

    struct DeliveryInput: Codable {
        let orderId: String
        let address: String
        let phone: String
        let itemCount: Int
    }

    // MARK: - Workflow Implementation

    func run(input: DeliveryInput) async throws -> String {
        // Step 1: Assign a driver
        let driverInfo = try await Workflow.executeActivity(
            PizzaActivities.Activities.AssignDriver.self,
            options: .init(startToCloseTimeout: .seconds(30)),
            input: PizzaActivities.AssignDriverInput(
                orderId: input.orderId,
                address: input.address,
                itemCount: input.itemCount
            )
        )

        // Step 2: Simulate delivery
        let deliveryResult = try await Workflow.executeActivity(
            PizzaActivities.Activities.DeliverOrder.self,
            options: .init(startToCloseTimeout: .seconds(30)),
            input: PizzaActivities.DeliverOrderInput(
                orderId: input.orderId,
                driverName: driverInfo.driverName,
                address: input.address,
                phone: input.phone
            )
        )

        return "\(driverInfo.driverName) (Driver #\(driverInfo.driverNumber)) - \(deliveryResult)"
    }
}
