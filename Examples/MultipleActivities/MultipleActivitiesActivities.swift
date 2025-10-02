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

/// Activities representing external service calls in an order fulfillment workflow.
///
/// Each activity simulates a real-world external system interaction that benefits
/// from Temporal's automatic retry and observability features.
@ActivityContainer
struct MultipleActivitiesActivities {
    // MARK: - Activity Input Types

    struct PaymentInput: Codable {
        let customerId: String
        let amount: Double
    }

    struct ReserveInventoryInput: Codable {
        let orderId: String
        let items: [String]
    }

    struct CreateShipmentInput: Codable {
        let orderId: String
        let customerId: String
        let items: [String]
    }

    struct SendConfirmationInput: Codable {
        let customerId: String
        let orderId: String
        let trackingNumber: String
    }

    struct UpdateOrderStatusInput: Codable {
        let orderId: String
        let status: String
    }
    private let inventoryService: InventoryService
    private let paymentService: PaymentService
    private let shippingService: ShippingService
    private let notificationService: NotificationService
    private let orderDatabase: OrderDatabase

    init(
        inventoryService: InventoryService,
        paymentService: PaymentService,
        shippingService: ShippingService,
        notificationService: NotificationService,
        orderDatabase: OrderDatabase
    ) {
        self.inventoryService = inventoryService
        self.paymentService = paymentService
        self.shippingService = shippingService
        self.notificationService = notificationService
        self.orderDatabase = orderDatabase
    }

    init() {
        self.inventoryService = FakeInventoryService()
        self.paymentService = FakePaymentService()
        self.shippingService = FakeShippingService()
        self.notificationService = FakeNotificationService()
        self.orderDatabase = FakeOrderDatabase()
    }

    /// Checks if all items are available in inventory.
    ///
    /// External call to inventory management system.
    @Activity
    func checkInventory(input: [String]) async throws -> String {
        print("📦 Checking inventory for \(input.count) item(s)...")

        let available = try await inventoryService.checkAvailability(items: input)

        guard available else {
            print("❌ Some items out of stock")
            throw ApplicationError(
                message: "One or more items out of stock",
                type: "OutOfStock",
                isNonRetryable: true
            )
        }
        print("✅ All items in stock")
        return "All items available"
    }

    /// Processes payment through payment gateway
    /// External call to payment processor (Stripe, PayPal, etc.)
    @Activity
    func processPayment(input: PaymentInput) async throws -> String {
        print("💳 Processing payment of $\(input.amount) for customer \(input.customerId)...")

        let paymentId = try await paymentService.charge(
            customerId: input.customerId,
            amount: input.amount
        )

        print("✅ Payment successful: \(paymentId)")
        return paymentId
    }

    /// Reserves inventory after successful payment.
    ///
    /// External call to inventory management system to update stock levels.
    @Activity
    func reserveInventory(input: ReserveInventoryInput) async throws {
        print("📦 Reserving inventory for order \(input.orderId)...")

        try await inventoryService.reserve(orderId: input.orderId, items: input.items)

        print("✅ Inventory reserved")
    }

    /// Creates shipment and returns tracking number
    /// External call to shipping provider.
    @Activity
    func createShipment(input: CreateShipmentInput) async throws -> String {
        print("📮 Creating shipment for order \(input.orderId)...")

        let trackingNumber = try await shippingService.createShipment(
            orderId: input.orderId,
            customerId: input.customerId,
            items: input.items
        )

        print("✅ Shipment created: \(trackingNumber)")
        return trackingNumber
    }

    /// Sends order confirmation to customer.
    ///
    /// External call to notification service (email, SMS, push notification).
    @Activity
    func sendConfirmation(input: SendConfirmationInput) async throws {
        print("📧 Sending confirmation to customer \(input.customerId)...")

        try await notificationService.sendConfirmation(
            customerId: input.customerId,
            orderId: input.orderId,
            trackingNumber: input.trackingNumber
        )

        print("✅ Confirmation sent")
    }

    /// Updates order status in database.
    ///
    /// External call to order management database.
    @Activity
    func updateOrderStatus(input: UpdateOrderStatusInput) async throws {
        print("💾 Updating order \(input.orderId) status to '\(input.status)'...")

        try await orderDatabase.updateStatus(orderId: input.orderId, status: input.status)

        print("✅ Order status updated")
    }
}
