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

@main
struct ErrorHandlingExample {
    static func main() async throws {
        let logger = Logger(label: "TemporalWorker")

        let namespace = "default"
        let taskQueue = "activity-errorhandling-queue"

        // Create worker configuration
        let workerConfiguration = TemporalWorker.Configuration(
            namespace: namespace,
            taskQueue: taskQueue,
            instrumentation: .init(serverHostname: "localhost")
        )

        // Create activities container
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

            // Wait for the worker and client to run
            try await Task.sleep(for: .seconds(1))

            print("Executing Error Handling Workflow")

            // Test scenario 1: Successful retry
            print("\n=== Testing successful retry scenario ===")
            do {
                let successResult = try await client.executeWorkflow(
                    type: ErrorHandlingWorkflow.self,
                    options: .init(id: "success-" + UUID().uuidString, taskQueue: taskQueue),
                    input: ErrorHandlingWorkflow.Scenario.success
                )
                print("Success Workflow Result:\n\(successResult)")
            } catch {
                // Don't crash the application; the workflow failed.
                print("Success scenario workflow failed: \(error)")
            }

            // Test scenario 2: Non-retryable failure
            print("\n=== Testing non-retryable failure scenario ===")
            do {
                let nonRetryableResult = try await client.executeWorkflow(
                    type: ErrorHandlingWorkflow.self,
                    options: .init(id: "fail-" + UUID().uuidString, taskQueue: taskQueue),
                    input: ErrorHandlingWorkflow.Scenario.nonRetryable
                )
                print("Non-retryable Workflow Result:\n\(nonRetryableResult)")
            } catch {
                // Expected for non-retryable errors; surface the failure but keep the app running.
                print("Non-retryable scenario workflow failed as expected: \(error)")
            }

            // Test scenario 3: Compensation pattern
            print("\n=== Testing compensation scenario ===")
            do {
                let compensationResult = try await client.executeWorkflow(
                    type: ErrorHandlingWorkflow.self,
                    options: .init(id: "compensate-" + UUID().uuidString, taskQueue: taskQueue),
                    input: ErrorHandlingWorkflow.Scenario.compensation
                )
                print("Compensation Workflow Result:\n\(compensationResult)")
            } catch {
                // Workflow may throw after compensation attempts; report and continue.
                print("Compensation scenario workflow failed: \(error)")
            }

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
