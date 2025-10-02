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

/// Demonstrates a realistic order fulfillment workflow that orchestrates multiple activities.
/// This example shows:
/// - Breaking down a complex business process into discrete activities
/// - Configuring appropriate retry policies for different types of operations
/// - Passing data between activities in a workflow
/// - Why certain operations should be activities (external API calls, database operations)
@Workflow
final class MultipleActivitiesWorkflow {
    struct OrderRequest: Codable {
        let orderId: String
        let customerId: String
        let items: [String]
        let totalAmount: Double
    }

    struct OrderResult: Codable {
        let orderId: String
        let status: String
        let paymentId: String
        let trackingNumber: String
    }

    func run(input: OrderRequest) async throws -> OrderResult {
        // Step 1: Validate inventory for all items
        // This is an activity because it queries external inventory systems
        _ = try await Workflow.executeActivity(
            MultipleActivitiesActivities.Activities.CheckInventory.self,
            options: .init(
                startToCloseTimeout: .seconds(30),
                retryPolicy: .init(
                    initialInterval: .milliseconds(500),
                    backoffCoefficient: 2.0,
                    maximumInterval: .seconds(10),
                    maximumAttempts: 3
                )
            ),
            input: input.items
        )

        // Step 2: Process payment with payment gateway
        // This is an activity because it calls an external payment API
        // Payment operations need careful retry handling to avoid double-charging
        let paymentId = try await Workflow.executeActivity(
            MultipleActivitiesActivities.Activities.ProcessPayment.self,
            options: .init(
                startToCloseTimeout: .seconds(60),
                retryPolicy: .init(
                    initialInterval: .seconds(1),
                    backoffCoefficient: 2.0,
                    maximumInterval: .seconds(30),
                    maximumAttempts: 5,
                    nonRetryableErrorTypes: ["InsufficientFunds", "InvalidCard"]
                )
            ),
            input: MultipleActivitiesActivities.PaymentInput(
                customerId: input.customerId,
                amount: input.totalAmount
            )
        )

        // Step 3: Reserve inventory after successful payment
        // This is an activity because it updates external inventory database
        try await Workflow.executeActivity(
            MultipleActivitiesActivities.Activities.ReserveInventory.self,
            options: .init(
                startToCloseTimeout: .seconds(30),
                retryPolicy: .init(
                    initialInterval: .milliseconds(500),
                    backoffCoefficient: 2.0,
                    maximumInterval: .seconds(10),
                    maximumAttempts: 3
                )
            ),
            input: MultipleActivitiesActivities.ReserveInventoryInput(
                orderId: input.orderId,
                items: input.items
            )
        )

        // Step 4: Create shipment and get tracking number
        // This is an activity because it integrates with shipping provider APIs
        let trackingNumber = try await Workflow.executeActivity(
            MultipleActivitiesActivities.Activities.CreateShipment.self,
            options: .init(
                startToCloseTimeout: .seconds(45),
                retryPolicy: .init(
                    initialInterval: .seconds(1),
                    backoffCoefficient: 2.0,
                    maximumInterval: .seconds(15),
                    maximumAttempts: 4
                )
            ),
            input: MultipleActivitiesActivities.CreateShipmentInput(
                orderId: input.orderId,
                customerId: input.customerId,
                items: input.items
            )
        )

        // Step 5: Send confirmation notification to customer
        // This is an activity because it calls external notification service (email/SMS)
        try await Workflow.executeActivity(
            MultipleActivitiesActivities.Activities.SendConfirmation.self,
            options: .init(
                startToCloseTimeout: .seconds(30),
                retryPolicy: .init(
                    initialInterval: .milliseconds(500),
                    backoffCoefficient: 2.0,
                    maximumInterval: .seconds(10),
                    maximumAttempts: 3
                )
            ),
            input: MultipleActivitiesActivities.SendConfirmationInput(
                customerId: input.customerId,
                orderId: input.orderId,
                trackingNumber: trackingNumber
            )
        )

        // Step 6: Update order status in database
        // This is an activity because it performs database I/O
        try await Workflow.executeActivity(
            MultipleActivitiesActivities.Activities.UpdateOrderStatus.self,
            options: .init(
                startToCloseTimeout: .seconds(30),
                retryPolicy: .init(
                    initialInterval: .milliseconds(500),
                    backoffCoefficient: 2.0,
                    maximumInterval: .seconds(10),
                    maximumAttempts: 3
                )
            ),
            input: MultipleActivitiesActivities.UpdateOrderStatusInput(
                orderId: input.orderId,
                status: "fulfilled"
            )
        )

        return OrderResult(
            orderId: input.orderId,
            status: "fulfilled",
            paymentId: paymentId,
            trackingNumber: trackingNumber
        )
    }
}
