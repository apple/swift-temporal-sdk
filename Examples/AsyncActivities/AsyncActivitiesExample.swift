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

/// Async Activities Example - NYC Film Permit Processing.
///
/// This example demonstrates parallel/concurrent activity execution patterns in Temporal:
///
/// - **Parallel Activity Execution**: Using `async let` to run multiple activities concurrently
/// - **Task Groups**: Processing multiple permits in parallel with `withThrowingTaskGroup`
/// - **Multiple Workers**: Running 5 workers simultaneously to distribute activity load
/// - **External API Integration**: Fetching data from NYC Open Data API with retry policies
/// - **Performance Comparison**: Sequential vs parallel processing with timing metrics
///
/// The example uses the NYC Film Permits API to demonstrate a data processing pipeline where:.
/// - Each permit undergoes multiple analysis steps (validation, location, categorization)
/// - Multiple permits are processed concurrently across workers
/// - Activities are distributed across worker instances for parallel execution
@main
struct AsyncActivitiesExample {
    /// Fetch permits from NYC API outside of workflow timing.
    static func fetchPermits(count: Int) async throws -> [FilmPermitActivities.FilmPermit] {
        let url = URL(string: "https://data.cityofnewyork.us/resource/tg4x-b46p.json?$limit=\(count)")!
        var request = URLRequest(url: url)
        request.timeoutInterval = 30
        request.httpMethod = "GET"

        let (data, _) = try await URLSession.shared.data(for: request)
        let decoder = JSONDecoder()
        return try decoder.decode([FilmPermitActivities.FilmPermit].self, from: data)
    }

    static func main() async throws {
        var logger = Logger(label: "TemporalWorker")
        logger.logLevel = .info

        let namespace = "default"
        let taskQueue = "film-permit-queue"

        print("🎬 NYC Film Permit Processing - Async Activities Example")
        print(String(repeating: "=", count: 70))
        print()

        // Create worker configuration
        let workerConfiguration = TemporalWorker.Configuration(
            namespace: namespace,
            taskQueue: taskQueue,
            instrumentation: .init(serverHostname: "localhost")
        )

        // Create activities
        let activities = FilmPermitActivities()

        // Helper to create a worker
        func createWorker(workerId: Int) throws -> TemporalWorker {
            var workerLogger = Logger(label: "TemporalWorker-\(workerId)")
            workerLogger.logLevel = .info

            return try TemporalWorker(
                configuration: workerConfiguration,
                target: .ipv4(address: "127.0.0.1", port: 7233),
                transportSecurity: .plaintext,
                activityContainers: activities,
                activities: [],
                workflows: [FilmPermitWorkflow.self],  // All workers can handle workflows
                logger: workerLogger
            )
        }

        // Create client
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

        try await withThrowingTaskGroup(of: Void.self) { group in
            // Start 5 workers
            print("🚀 Starting Workers:")
            for workerId in 1...5 {
                let worker = try createWorker(workerId: workerId)
                group.addTask {
                    print("  ✅ Worker \(workerId) started (PID: \(ProcessInfo.processInfo.processIdentifier))")
                    try await worker.run()
                }
            }

            // Start client
            group.addTask {
                try await client.run()
            }

            // Wait for worker and client to initialize
            try await Task.sleep(for: .seconds(2))

            print()
            print(String(repeating: "=", count: 70))
            print()

            // Fetch permits once, outside of workflow timing
            print("📥 Fetching film permits from NYC API...")
            let permits = try await fetchPermits(count: 100)  // Fetch large sample
            print("✅ Fetched \(permits.count) permits")
            print()

            print(String(repeating: "=", count: 70))
            print()

            // Run sequential processing first
            print("⏳ Test 1: Sequential Processing")
            print(String(repeating: "-", count: 70))
            let sequentialWorkflowId = "PERMITS-SEQ-\(UUID().uuidString.prefix(8))"
            let sequentialRequest = FilmPermitWorkflow.BatchRequest(
                permits: permits,
                mode: .sequential
            )

            print("🔗 View in Temporal UI:")
            print("  http://localhost:8233/namespaces/\(namespace)/workflows/\(sequentialWorkflowId)")
            print()

            let sequentialStart = Date()
            let sequentialResult = try await client.executeWorkflow(
                type: FilmPermitWorkflow.self,
                options: .init(id: sequentialWorkflowId, taskQueue: taskQueue),
                input: sequentialRequest
            )
            let sequentialDuration = Date().timeIntervalSince(sequentialStart)

            print()
            print("✅ Sequential Processing Complete:")
            print("  Total permits: \(sequentialResult.report.totalPermits)")
            print("  Valid permits: \(sequentialResult.report.validPermits)")
            print("  Total time: \(String(format: "%.2f", sequentialDuration))s")
            print("  Average per permit: \(String(format: "%.2f", sequentialDuration / Double(sequentialResult.report.totalPermits)))s")
            print()

            // Display borough breakdown
            if !sequentialResult.report.byBorough.isEmpty {
                print("  By Borough:")
                for (borough, count) in sequentialResult.report.byBorough.sorted(by: { $0.value > $1.value }) {
                    print("    • \(borough): \(count) permits")
                }
                print()
            }

            // Run parallel processing
            print(String(repeating: "=", count: 70))
            print()
            print("⚡ Test 2: Parallel Processing")
            print(String(repeating: "-", count: 70))
            let parallelWorkflowId = "PERMITS-PAR-\(UUID().uuidString.prefix(8))"
            let parallelRequest = FilmPermitWorkflow.BatchRequest(
                permits: permits,
                mode: .parallel
            )

            print("🔗 View in Temporal UI:")
            print("  http://localhost:8233/namespaces/\(namespace)/workflows/\(parallelWorkflowId)")
            print()
            print("📊 Processing \(permits.count) permits in parallel...")
            print()

            let parallelStart = Date()
            let parallelResult = try await client.executeWorkflow(
                type: FilmPermitWorkflow.self,
                options: .init(id: parallelWorkflowId, taskQueue: taskQueue),
                input: parallelRequest
            )
            let parallelDuration = Date().timeIntervalSince(parallelStart)

            print()
            print("✅ Parallel Processing Complete:")
            print("  Total permits: \(parallelResult.report.totalPermits)")
            print("  Valid permits: \(parallelResult.report.validPermits)")
            print("  Total time: \(String(format: "%.2f", parallelDuration))s")
            print("  Average per permit: \(String(format: "%.2f", parallelDuration / Double(parallelResult.report.totalPermits)))s")
            print()

            // Display category breakdown
            if !parallelResult.report.byCategory.isEmpty {
                print("  By Category:")
                for (category, count) in parallelResult.report.byCategory.sorted(by: { $0.value > $1.value }).prefix(5) {
                    print("    • \(category): \(count) permits")
                }
                print()
            }

            // Performance comparison
            print(String(repeating: "=", count: 70))
            print()
            print("📈 Performance Summary:")
            print(String(repeating: "-", count: 70))
            print("  Sequential: \(String(format: "%.2f", sequentialDuration))s for \(permits.count) permits")
            print("  Parallel:   \(String(format: "%.2f", parallelDuration))s for \(permits.count) permits")
            print()
            let speedup = sequentialDuration / parallelDuration
            print("  Speedup: \(String(format: "%.1f", speedup))x")
            print("  (Parallel processing is \(String(format: "%.1f", speedup))x faster)")
            print()
            print("✅ Example completed successfully!")
            print()

            // Cancel worker and client
            group.cancelAll()
        }
    }
}
#else
@main
struct AsyncActivitiesExample {
    static func main() async throws {
        fatalError("GRPCNIOTransport trait disabled")
    }
}
#endif
