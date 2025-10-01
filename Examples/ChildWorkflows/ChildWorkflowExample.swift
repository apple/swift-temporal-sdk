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

#if GRPCNIOTransport
import Foundation
import GRPCNIOTransportHTTP2Posix
import Logging
import Temporal

/// Child Workflows Example - Pizza Restaurant
///
/// This example demonstrates Temporal child workflows through a pizza restaurant order
/// fulfillment system. It showcases:
///
/// **Parent Workflow:**
/// - `PizzaOrderWorkflow` - Orchestrates the complete order fulfillment process
///
/// **Child Workflows:**
/// - `MakePizzaWorkflow` - Makes individual pizzas (executed in parallel)
/// - `PrepareSidesWorkflow` - Prepares sides (executed in parallel with pizzas)
/// - `AssignDeliveryWorkflow` - Assigns driver and handles delivery (sequential)
///
/// **Key Patterns:**
/// - Parallel child workflow execution using task groups (multiple pizzas)
/// - Sequential child workflow execution (delivery after cooking)
/// - Custom workflow IDs for child workflows
/// - Result aggregation from multiple child workflows
@main
struct ChildWorkflowExample {
    static func main() async throws {
        let logger = Logger(label: "TemporalWorker")

        let namespace = "default"
        let taskQueue = "pizza-queue"

        // Create worker configuration
        let workerConfiguration = TemporalWorker.Configuration(
            namespace: namespace,
            taskQueue: taskQueue,
            instrumentation: .init(serverHostname: "localhost")
        )

        // Create the worker with all workflows registered
        let worker = try TemporalWorker(
            configuration: workerConfiguration,
            target: .ipv4(address: "127.0.0.1", port: 7233),
            transportSecurity: .plaintext,
            activityContainers: PizzaActivities(),
            activities: [],
            workflows: [
                PizzaOrderWorkflow.self,
                MakePizzaWorkflow.self,
                PrepareSidesWorkflow.self,
                AssignDeliveryWorkflow.self,
            ],
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

            print("🍕 Pizza Restaurant - Child Workflows Example")
            print(String(repeating: "=", count: 60))
            print()

            // Create a sample order
            let orderId = "ORDER-\(Int.random(in: 10000...99999))"
            let orderInput = PizzaOrderWorkflow.OrderInput(
                orderId: orderId,
                pizzas: [
                    PizzaOrderWorkflow.PizzaSpec(size: "large", toppings: ["pepperoni", "mushrooms", "olives"]),
                    PizzaOrderWorkflow.PizzaSpec(size: "large", toppings: ["sausage", "peppers", "onions"]),
                    PizzaOrderWorkflow.PizzaSpec(size: "medium", toppings: ["margherita"]),
                ],
                sides: ["wings", "garlic bread"],
                deliveryAddress: "123 Main St, Apt 4B",
                customerPhone: "555-0123"
            )

            print("📝 New Order: \(orderId)")
            print("   • \(orderInput.pizzas.count) pizza(s)")
            for (index, pizza) in orderInput.pizzas.enumerated() {
                print("     - Pizza #\(index + 1): \(pizza.size) with \(pizza.toppings.joined(separator: ", "))")
            }
            print("   • Sides: \(orderInput.sides.joined(separator: ", "))")
            print("   • Delivery to: \(orderInput.deliveryAddress)")
            print()

            let workflowId = "pizza-order-" + UUID().uuidString
            print("🔗 View in Temporal UI:")
            print("   http://localhost:8233/namespaces/\(namespace)/workflows/\(workflowId)")
            print()
            print("⏳ Executing workflow...")
            print()

            // Start workflow
            let handle = try await client.startWorkflow(
                type: PizzaOrderWorkflow.self,
                options: .init(id: workflowId, taskQueue: taskQueue),
                input: orderInput
            )

            // Wait for result
            let result = try await handle.result()

            print()
            print(String(repeating: "=", count: 60))
            print("✅ Order Completed!")
            print(String(repeating: "=", count: 60))
            print("Order ID: \(result.orderId)")
            print()
            print("Pizzas:")
            for pizzaResult in result.pizzaResults {
                print("  ✓ \(pizzaResult)")
            }
            print()
            print("Sides:")
            print("  ✓ \(result.sidesResult)")
            print()
            print("Delivery:")
            print("  ✓ \(result.deliveryResult)")
            print()
            print("Total Time: \(result.totalTime)")
            print()

            print(String(repeating: "=", count: 60))
            print("Child Workflows Demonstrated:")
            print("  • \(orderInput.pizzas.count) MakePizzaWorkflow children (parallel)")
            print("  • 1 PrepareSidesWorkflow child (parallel with pizzas)")
            print("  • 1 AssignDeliveryWorkflow child (sequential)")
            print()
            print("View parent and child workflows in Temporal UI:")
            print("  http://localhost:8233")
            print(String(repeating: "=", count: 60))

            // Cancel the client and worker
            group.cancelAll()
        }
    }
}
#else
@main
struct ChildWorkflowExample {
    static func main() async throws {
        fatalError("GRPCNIOTransport trait disabled")
    }
}
#endif
