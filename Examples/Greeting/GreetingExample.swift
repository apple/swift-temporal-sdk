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

@main
struct GreetingExample {
    static func main() async throws {
        let logger = Logger(label: "TemporalWorker")

        let namespace = "default"
        let taskQueue = "greeting-queue"

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
            activityContainers: GreetingActivities(),
            activities: [],
            workflows: [GreetingWorkflow.self],
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

            print("Executing workflow")
            let greeting = try await client.executeWorkflow(
                type: GreetingWorkflow.self,
                options: .init(id: UUID().uuidString, taskQueue: taskQueue),
                input: "Max"
            )

            print(greeting)

            // Cancel the client and worker
            group.cancelAll()
        }
    }
}
#else
@main
struct GreetingExample {
    static func main() async throws {
        fatalError("GRPCNIOTransport trait disabled")
    }
}
#endif
