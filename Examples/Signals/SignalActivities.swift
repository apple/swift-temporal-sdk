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

/// Activities for order processing workflow demonstrating external system interactions.
@ActivityContainer
struct SignalActivities {
    // MARK: - Activity Input Types

    struct ProcessOrderInput: Codable {
        let orderId: String
        let items: [String]
    }

    struct ShipOrderInput: Codable {
        let orderId: String
        let priority: String
    }

    // MARK: - Activities

    /// Processes an order.
    @Activity
    func processOrder(input: ProcessOrderInput) async throws -> String {
        print("📦 Processing order \(input.orderId) with \(input.items.count) item(s)...")
        try await Task.sleep(for: .seconds(2))
        print("✅ Order processed")
        return "PROCESSED-\(input.orderId)"
    }

    /// Ships an order.
    @Activity
    func shipOrder(input: ShipOrderInput) async throws -> String {
        print("🚚 Shipping order \(input.orderId) with \(input.priority) priority...")
        try await Task.sleep(for: .seconds(2))
        let trackingNumber = "TRACK-\(UUID().uuidString.prefix(8))"
        print("✅ Order shipped: \(trackingNumber)")
        return trackingNumber
    }

    /// Notifies customer.
    @Activity
    func notifyCustomer(input: String) async throws {
        print("📧 Notifying customer: \(input)")
        try await Task.sleep(for: .milliseconds(500))
        print("✅ Notification sent")
    }
}
