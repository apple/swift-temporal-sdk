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

// MARK: - Service Protocols

/// Simulates an inventory management system
protocol InventoryService: Sendable {
    func checkAvailability(items: [String]) async throws -> Bool
    func reserve(orderId: String, items: [String]) async throws
}

/// Simulates a payment processing service (e.g., Stripe, PayPal)
protocol PaymentService: Sendable {
    func charge(customerId: String, amount: Double) async throws -> String
}

/// Simulates a shipping provider service (e.g., FedEx, UPS)
protocol ShippingService: Sendable {
    func createShipment(orderId: String, customerId: String, items: [String]) async throws -> String
}

/// Simulates a notification service (e.g., email, SMS, push notifications)
protocol NotificationService: Sendable {
    func sendConfirmation(customerId: String, orderId: String, trackingNumber: String) async throws
}

/// Simulates an order management database
protocol OrderDatabase: Sendable {
    func updateStatus(orderId: String, status: String) async throws
}

// MARK: - Fake Implementations

/// Simulates inventory management with realistic delays and occasional failures
actor FakeInventoryService: InventoryService {
    private var inventory: [String: Int] = [
        "item-001": 10,
        "item-002": 5,
        "item-003": 15,
        "laptop": 8,
        "mouse": 50,
        "keyboard": 30,
    ]

    private var reservations: [String: [String]] = [:]

    func checkAvailability(items: [String]) async throws -> Bool {
        // Simulate API call delay
        try await Task.sleep(for: .milliseconds(200))

        for item in items {
            guard let stock = inventory[item], stock > 0 else {
                return false
            }
        }
        return true
    }

    func reserve(orderId: String, items: [String]) async throws {
        // Simulate API call delay
        try await Task.sleep(for: .milliseconds(150))

        for item in items {
            if let stock = inventory[item], stock > 0 {
                inventory[item] = stock - 1
            }
        }
        reservations[orderId] = items
    }
}

/// Simulates payment processing with realistic delays and idempotency
actor FakePaymentService: PaymentService {
    private var processedPayments: [String: String] = [:]

    func charge(customerId: String, amount: Double) async throws -> String {
        // Simulate payment gateway API call delay
        try await Task.sleep(for: .milliseconds(500))

        // Idempotency: return existing payment ID if already processed
        let idempotencyKey = "\(customerId)-\(amount)"
        if let existingPaymentId = processedPayments[idempotencyKey] {
            return existingPaymentId
        }

        let paymentId = "pay_\(UUID().uuidString.prefix(12))"
        processedPayments[idempotencyKey] = paymentId
        return paymentId
    }
}

/// Simulates shipping provider API with realistic delays
actor FakeShippingService: ShippingService {
    private var shipments: [String: String] = [:]

    func createShipment(orderId: String, customerId: String, items: [String]) async throws -> String {
        // Simulate shipping provider API call delay
        try await Task.sleep(for: .milliseconds(300))

        let trackingNumber = "TRK\(Int.random(in: 100000000...999999999))"
        shipments[orderId] = trackingNumber
        return trackingNumber
    }
}

/// Simulates notification service (email/SMS) with realistic delays
actor FakeNotificationService: NotificationService {
    private var sentNotifications: Set<String> = []

    func sendConfirmation(customerId: String, orderId: String, trackingNumber: String) async throws {
        // Simulate notification service API call delay
        try await Task.sleep(for: .milliseconds(250))

        let notificationKey = "\(customerId)-\(orderId)"
        sentNotifications.insert(notificationKey)
    }
}

/// Simulates order management database with realistic delays
actor FakeOrderDatabase: OrderDatabase {
    private var orders: [String: String] = [:]

    func updateStatus(orderId: String, status: String) async throws {
        // Simulate database write delay
        try await Task.sleep(for: .milliseconds(100))

        orders[orderId] = status
    }
}
