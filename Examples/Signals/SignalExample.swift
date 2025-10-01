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

/// Signal, Query, and Update Example
///
/// This example demonstrates Temporal's message passing capabilities through a realistic
/// order processing scenario. It showcases:
///
/// **Signals** - Asynchronous messages that mutate workflow state:
/// - `pause()` - Pauses order processing
/// - `resume()` - Resumes a paused order
/// - `cancel()` - Cancels the order
///
/// **Queries** - Synchronous read-only operations to inspect workflow state:
/// - `getStatus()` - Returns current order status, state, and progress
///
/// **Updates** - Synchronous operations that both mutate and return values:
/// - `setPriority()` - Changes order priority with validation
///
/// The example demonstrates:
/// - How to use Workflow.condition to wait for signals
/// - Proper validation in update handlers
/// - State management across signals, queries, and updates
/// - Clean separation between workflow logic and external communication
@main
struct SignalExample {
    static func main() async throws {
        let logger = Logger(label: "TemporalWorker")

        let namespace = "default"
        let taskQueue = "signal-queue"

        // Create worker configuration
        let workerConfiguration = TemporalWorker.Configuration(
            namespace: namespace,
            taskQueue: taskQueue,
            instrumentation: .init(serverHostname: "localhost")
        )

        // Create the worker
        let worker = try TemporalWorker(
            configuration: workerConfiguration,
            target: .ipv4(address: "127.0.0.1", port: 7233),
            transportSecurity: .plaintext,
            activityContainers: SignalActivities(),
            activities: [],
            workflows: [SignalWorkflow.self],
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

            print("🔔 Signal, Query, and Update Example")
            print(String(repeating: "=", count: 60))
            print()

            let orderInput = SignalWorkflow.OrderInput(
                orderId: "ORDER-12345",
                customerId: "customer-001",
                items: ["Widget A", "Widget B", "Widget C"]
            )

            let workflowId = "order-processing-" + UUID().uuidString
            print("🔗 View in Temporal UI:")
            print("  http://localhost:8233/namespaces/\(namespace)/workflows/\(workflowId)")
            print()

            // Start workflow asynchronously
            let handle = try await client.startWorkflow(
                type: SignalWorkflow.self,
                options: .init(id: workflowId, taskQueue: taskQueue),
                input: orderInput
            )

            print("✅ Workflow started: \(workflowId)")
            print()

            // Wait a moment for workflow to start processing
            try await Task.sleep(for: .seconds(1))

            // Query 1: Check initial status
            print("📊 Query: Getting initial status...")
            let status1 = try await handle.query(queryType: SignalWorkflow.GetStatus.self)
            print("   Status: \(status1.currentState)")
            print("   Completed steps: \(status1.completedSteps)")
            print()

            // Update: Change priority to expedited
            print("🔄 Update: Changing priority to expedited...")
            do {
                let updateResult = try await handle.executeUpdate(
                    updateType: SignalWorkflow.SetPriority.self,
                    input: SignalWorkflow.SetPriorityInput(priority: "expedited")
                )
                print("   ✅ \(updateResult)")
            } catch {
                print("   ❌ Update failed: \(error)")
            }
            print()

            // Wait for order processing to complete
            try await Task.sleep(for: .seconds(2))

            // Signal 1: Pause the workflow
            print("⏸️  Signal: Pausing workflow...")
            try await handle.signal(signalType: SignalWorkflow.Pause.self)
            print("   ✅ Pause signal sent")
            print()

            // Query 2: Verify workflow is paused
            try await Task.sleep(for: .milliseconds(500))
            print("📊 Query: Checking if workflow is paused...")
            let status2 = try await handle.query(queryType: SignalWorkflow.GetStatus.self)
            print("   Is paused: \(status2.isPaused)")
            print("   Current state: \(status2.currentState)")
            print("   Completed steps: \(status2.completedSteps)")
            print()

            // Try to update priority while paused (should still work if not shipping yet)
            print("🔄 Update: Trying to change priority while paused...")
            do {
                let updateResult = try await handle.executeUpdate(
                    updateType: SignalWorkflow.SetPriority.self,
                    input: SignalWorkflow.SetPriorityInput(priority: "overnight")
                )
                print("   ✅ \(updateResult)")
            } catch {
                print("   ❌ Update failed (expected if already shipping): \(error.localizedDescription)")
            }
            print()

            // Wait while paused
            print("⏳ Waiting 2 seconds while workflow is paused...")
            try await Task.sleep(for: .seconds(2))

            // Query 3: Confirm still paused
            print("📊 Query: Confirming workflow is still paused...")
            let status3 = try await handle.query(queryType: SignalWorkflow.GetStatus.self)
            print("   Is paused: \(status3.isPaused)")
            print("   Current state: \(status3.currentState)")
            print()

            // Signal 2: Resume the workflow
            print("▶️  Signal: Resuming workflow...")
            try await handle.signal(signalType: SignalWorkflow.Resume.self)
            print("   ✅ Resume signal sent")
            print()

            // Query 4: Verify workflow is resumed
            try await Task.sleep(for: .milliseconds(500))
            print("📊 Query: Checking if workflow is resumed...")
            let status4 = try await handle.query(queryType: SignalWorkflow.GetStatus.self)
            print("   Is paused: \(status4.isPaused)")
            print("   Current state: \(status4.currentState)")
            print()

            // Wait for workflow to complete
            print("⏳ Waiting for workflow to complete...")
            let result = try await handle.result()

            print()
            print(String(repeating: "=", count: 60))
            print("✅ Workflow Completed!")
            print(String(repeating: "=", count: 60))
            print("Order ID: \(result.orderId)")
            print("Status: \(result.status)")
            print("Priority: \(result.priority)")
            if let processedId = result.processedId {
                print("Processed ID: \(processedId)")
            }
            if let trackingNumber = result.trackingNumber {
                print("Tracking Number: \(trackingNumber)")
            }
            print()

            print(String(repeating: "=", count: 60))
            print("Example completed! Demonstrated:")
            print("- ⏸️  Pause signal")
            print("- ▶️  Resume signal")
            print("- 📊 Status queries")
            print("- 🔄 Priority updates with validation")
            print(String(repeating: "=", count: 60))

            // Cancel the client and worker
            group.cancelAll()
        }
    }
}
#else
@main
struct SignalExample {
    static func main() async throws {
        fatalError("GRPCNIOTransport trait disabled")
    }
}
#endif
