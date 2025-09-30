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
struct MultipleActivitiesExample {
    static func main() async throws {
        let logger = Logger(label: "TemporalWorker")

        let namespace = "default"
        let taskQueue = "multiple-activities-queue"

        // Create worker configuration
        let workerConfiguration = TemporalWorker.Configuration(
            namespace: namespace,
            taskQueue: taskQueue,
            instrumentation: .init(serverHostname: "localhost")
        )

        // Create fake database client and activities
        let activities = MultipleActivitiesActivities()

        // Create the worker with activities
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

            // Wait for the worker and client to run
            try await Task.sleep(for: .seconds(1))

            print("Executing Multiple Activities Workflow with Database Operations")
            let result = try await client.executeWorkflow(
                type: MultipleActivitiesWorkflow.self,
                options: .init(id: UUID().uuidString, taskQueue: taskQueue),
                input: "user1"  // Use a user key that exists in our fake database
            )

            print("Workflow Result: \(result)")

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
