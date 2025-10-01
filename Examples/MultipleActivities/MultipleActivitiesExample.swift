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

#if GRPCNIOTransport
import Foundation
import GRPCNIOTransportHTTP2Posix
import Logging
import Temporal

/// Order Fulfillment Example
///
/// This example demonstrates how to orchestrate multiple activities in a Temporal workflow
/// to implement a realistic order fulfillment process. It showcases:
///
/// - **Activity Orchestration**: Coordinating multiple external service calls
/// - **Retry Policies**: Configuring different retry strategies for different operations
/// - **Reliability**: Automatic retries and failure handling for transient errors
/// - **Observability**: Clear logging and activity progress tracking
///
/// The workflow implements a complete e-commerce order flow:
/// 1. Check inventory availability
/// 2. Process payment
/// 3. Reserve inventory
/// 4. Create shipment
/// 5. Send confirmation
/// 6. Update order status
///
/// Each step is implemented as a separate activity, representing a call to an external
/// service (payment gateway, shipping provider, notification service, etc.). Temporal
/// ensures reliable execution with automatic retries, even if the worker crashes or
/// activities fail temporarily.
@main
struct MultipleActivitiesExample {
    static func main() async throws {
        let logger = Logger(label: "TemporalWorker")

        let namespace = "default"
        let taskQueue = "order-fulfillment-queue"

        // Create worker configuration
        let workerConfiguration = TemporalWorker.Configuration(
            namespace: namespace,
            taskQueue: taskQueue,
            instrumentation: .init(serverHostname: "localhost")
        )

        // Create activities with fake external service implementations
        let activities = MultipleActivitiesActivities()

        // Create the worker with activities and workflows
        let worker = try TemporalWorker(
            configuration: workerConfiguration,
            target: .ipv4(address: "127.0.0.1", port: 7233),
            transportSecurity: .plaintext,
            activityContainers: activities,
            activities: [],
            workflows: [MultipleActivitiesWorkflow.self],
            logger: logger
        )

        let client = try TemporalClient(
            target: .ipv4(address: "127.0.0.1", port: 7233),
            transportSecurity: .plaintext,
            configuration: .init(
                instrumentation: .init(
                    serverHostname: "localhost"
                )
            ),
            logger: logger
        )

        try await withThrowingTaskGroup { group in
            group.addTask {
                try await worker.run()
            }

            group.addTask {
                try await client.run()
            }

            // Wait for the worker and client to initialize
            try await Task.sleep(for: .seconds(1))

            print("🛒 Starting Order Fulfillment Workflow Example")
            print(String(repeating: "=", count: 60))

            // Create a sample order
            let orderRequest = MultipleActivitiesWorkflow.OrderRequest(
                orderId: "ORD-\(UUID().uuidString.prefix(8))",
                customerId: "customer-123",
                items: ["laptop", "mouse", "keyboard"],
                totalAmount: 1299.99
            )

            print("\n📋 Order Details:")
            print("  Order ID: \(orderRequest.orderId)")
            print("  Customer: \(orderRequest.customerId)")
            print("  Items: \(orderRequest.items.joined(separator: ", "))")
            print("  Total: $\(orderRequest.totalAmount)")
            print()

            do {
                let result = try await client.executeWorkflow(
                    type: MultipleActivitiesWorkflow.self,
                    options: .init(id: orderRequest.orderId, taskQueue: taskQueue),
                    input: orderRequest
                )

                print("\n" + String(repeating: "=", count: 60))
                print("✅ Order Fulfilled Successfully!")
                print(String(repeating: "=", count: 60))
                print("📦 Order Status: \(result.status)")
                print("💳 Payment ID: \(result.paymentId)")
                print("🚚 Tracking Number: \(result.trackingNumber)")
                print()
            } catch {
                print("\n" + String(repeating: "=", count: 60))
                print("❌ Order Fulfillment Failed")
                print(String(repeating: "=", count: 60))
                print("Error: \(error.localizedDescription)")
                print()
            }

            // Cancel the client and worker
            group.cancelAll()
        }
    }
}
#else
@main
struct MultipleActivitiesExample {
    static func main() async throws {
        fatalError("GRPCNIOTransport trait disabled")
    }
}
#endif
