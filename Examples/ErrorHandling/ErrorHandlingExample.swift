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

/// Travel Booking Error Handling Example.
///
/// This example demonstrates Temporal's error handling capabilities through a realistic.
/// travel booking scenario. It showcases:
///
/// **Scenario 1: Retry with Exponential Backoff**
/// - Transient failures are automatically retried
/// - Shows how Temporal handles temporary service outages
/// - Demonstrates eventual success after retries
///
/// **Scenario 2: Saga Pattern / Compensation (Success)**
/// - Multi-step transaction where a later step fails
/// - Automatic rollback of earlier successful steps
/// - Shows proper compensation/undo logic
///
/// **Scenario 3: Workflow Failure (Compensation Fails)**
/// - Multi-step transaction where payment fails
/// - Compensation itself fails (systems are down)
/// - Shows how workflows fail when compensation is impossible
/// - Demonstrates need for manual intervention
///
/// The example uses structured types (no string parsing) and clean workflow code.
/// (no print statements in workflows, only in activities).
@main
struct ErrorHandlingExample {
    static func main() async throws {
        let logger = Logger(label: "TemporalWorker")

        let namespace = "default"
        let taskQueue = "travel-booking-queue"

        // Create worker configuration
        let workerConfiguration = TemporalWorker.Configuration(
            namespace: namespace,
            taskQueue: taskQueue,
            instrumentation: .init(serverHostname: "localhost")
        )

        // Create activities with fake travel booking services
        let activities = ErrorHandlingActivities()

        // Create the worker
        let worker = try TemporalWorker(
            configuration: workerConfiguration,
            target: .ipv4(address: "127.0.0.1", port: 7233),
            transportSecurity: .plaintext,
            activityContainers: activities,
            activities: [],
            workflows: [ErrorHandlingWorkflow.self],
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

            print("✈️  Travel Booking Error Handling Example")
            print(String(repeating: "=", count: 60))
            print()

            // Scenario 1: Successful booking with automatic retry
            print("📋 Scenario 1: Retry with Exponential Backoff")
            print(String(repeating: "-", count: 60))

            let successfulBooking = ErrorHandlingWorkflow.TravelBookingRequest(
                customerId: "customer-001",
                flightId: "FL-NYC-LAX-101",
                hotelId: "HOTEL-LAX-DOWNTOWN",
                amount: 999.99,
                simulateFailure: false,  // Payment will succeed
                simulateCompensationFailure: false
            )

            let workflowId1 = "travel-booking-success-" + UUID().uuidString
            print("🔗 View in Temporal UI:")
            print("  http://localhost:8233/namespaces/\(namespace)/workflows/\(workflowId1)")
            print("\nThis scenario shows how Temporal automatically retries transient")
            print("failures. Flight and hotel reservations will fail initially but")
            print("succeed after retries, demonstrating Temporal's reliability.\n")

            do {
                let result = try await client.executeWorkflow(
                    type: ErrorHandlingWorkflow.self,
                    options: .init(
                        id: workflowId1,
                        taskQueue: taskQueue
                    ),
                    input: successfulBooking
                )

                print("\n" + String(repeating: "=", count: 60))
                print("✅ Scenario 1 Complete!")
                print(String(repeating: "=", count: 60))
                print("Status: \(result.status)")
                print("Message: \(result.message)")
                if let flightId = result.flightReservationId {
                    print("Flight: \(flightId)")
                }
                if let hotelId = result.hotelReservationId {
                    print("Hotel: \(hotelId)")
                }
                if let paymentId = result.paymentId {
                    print("Payment: \(paymentId)")
                }
                print()
            } catch {
                print("Scenario 1 failed unexpectedly: \(error)\n")
            }

            // Scenario 2: Compensation/Saga pattern
            print("\n📋 Scenario 2: Saga Pattern / Compensation")
            print(String(repeating: "-", count: 60))

            let failedBooking = ErrorHandlingWorkflow.TravelBookingRequest(
                customerId: "customer-002",
                flightId: "FL-LAX-NYC-202",
                hotelId: "HOTEL-NYC-TIMES-SQUARE",
                amount: 1499.99,
                simulateFailure: true,  // Payment will fail with insufficient funds
                simulateCompensationFailure: false  // Compensation will succeed
            )

            let workflowId2 = "travel-booking-compensation-" + UUID().uuidString
            print("🔗 View in Temporal UI:")
            print("  http://localhost:8233/namespaces/\(namespace)/workflows/\(workflowId2)")
            print("\nThis scenario demonstrates the Saga pattern. Flight and hotel are")
            print("reserved successfully, but payment fails (insufficient funds).")
            print("Temporal automatically compensates by cancelling both reservations")
            print("in reverse order, ensuring no partial state is left behind.\n")

            do {
                let result = try await client.executeWorkflow(
                    type: ErrorHandlingWorkflow.self,
                    options: .init(
                        id: workflowId2,
                        taskQueue: taskQueue
                    ),
                    input: failedBooking
                )

                print("\n" + String(repeating: "=", count: 60))
                print("🔄 Scenario 2 Complete!")
                print(String(repeating: "=", count: 60))
                print("Status: \(result.status)")
                print("Message: \(result.message)")
                if let flightId = result.flightReservationId {
                    print("Flight (cancelled): \(flightId)")
                }
                if let hotelId = result.hotelReservationId {
                    print("Hotel (cancelled): \(hotelId)")
                }
                print()
            } catch {
                print("Scenario 2 failed unexpectedly: \(error)\n")
            }

            // Scenario 3: Workflow failure (compensation fails)
            print("\n📋 Scenario 3: Workflow Failure (Compensation Fails)")
            print(String(repeating: "-", count: 60))

            let criticalFailure = ErrorHandlingWorkflow.TravelBookingRequest(
                customerId: "customer-003",
                flightId: "FL-SFO-BOS-303",
                hotelId: "HOTEL-BOS-HARBOR",
                amount: 1899.99,
                simulateFailure: true,  // Payment will fail
                simulateCompensationFailure: true  // Compensation will ALSO fail
            )

            let workflowId3 = "travel-booking-critical-" + UUID().uuidString
            print("🔗 View in Temporal UI:")
            print("  http://localhost:8233/namespaces/\(namespace)/workflows/\(workflowId3)")
            print("\nThis scenario demonstrates a critical failure. Flight and hotel are")
            print("reserved successfully, but payment fails. When attempting to cancel")
            print("the reservations, BOTH cancellation systems are down. The workflow")
            print("fails completely, requiring manual intervention to clean up.\n")

            do {
                let result = try await client.executeWorkflow(
                    type: ErrorHandlingWorkflow.self,
                    options: .init(
                        id: workflowId3,
                        taskQueue: taskQueue
                    ),
                    input: criticalFailure
                )

                print("\n" + String(repeating: "=", count: 60))
                print("⚠️  Scenario 3 Complete (Unexpected)")
                print(String(repeating: "=", count: 60))
                print("Status: \(result.status)")
                print("Message: \(result.message)")
                print()
            } catch {
                print("\n" + String(repeating: "=", count: 60))
                print("❌ Scenario 3: WORKFLOW FAILED")
                print(String(repeating: "=", count: 60))
                print("This is expected! The workflow failed because compensation")
                print("was impossible. In production, this would trigger alerts")
                print("for manual intervention.\n")
                print("Error details:")
                print(error.localizedDescription)
                print()
            }

            print(String(repeating: "=", count: 60))
            print("Example completed! All three scenarios demonstrated.")
            print(String(repeating: "=", count: 60))

            // Cancel the client and worker
            group.cancelAll()
        }
    }
}
#else
@main
struct ErrorHandlingExample {
    static func main() async throws {
        fatalError("GRPCNIOTransport trait disabled")
    }
}
#endif
