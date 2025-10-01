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

#if GRPCNIOTransport && canImport(Vision)
import Foundation
import GRPCNIOTransportHTTP2Posix
import Logging
import Temporal

/// Async Activities Example - Lemon Quality Control
///
/// This example demonstrates parallel/concurrent activity execution patterns in Temporal:
///
/// - **Parallel Activity Execution**: Using `async let` to run multiple activities concurrently
/// - **Task Groups**: Processing multiple images in parallel with `withThrowingTaskGroup`
/// - **Multiple Workers**: Running 5 workers simultaneously to distribute activity load
/// - **Real Computer Vision**: Using Apple's Vision framework to analyze actual images
/// - **Performance Comparison**: Sequential vs parallel processing with timing metrics
///
/// The example uses the lemon-dataset (2,690 annotated lemon images) to demonstrate
/// a realistic quality control pipeline where:
/// - Each image undergoes multiple analysis steps (quality check, defect detection, attributes)
/// - Multiple images are processed concurrently across workers
/// - Activities are distributed across worker instances for true parallelism
@main
struct AsyncActivitiesExample {
    static func main() async throws {
        var logger = Logger(label: "TemporalWorker")
        logger.logLevel = .info

        let namespace = "default"
        let taskQueue = "lemon-quality-queue"

        // Determine dataset path
        let datasetPath = "\(FileManager.default.currentDirectoryPath)/Examples/AsyncActivities/lemon-dataset/data/lemon-dataset"

        guard FileManager.default.fileExists(atPath: datasetPath) else {
            print("❌ Error: Lemon dataset not found at \(datasetPath)")
            print("📥 Please run: git submodule update --init --recursive")
            print("   Then extract: unzip Examples/AsyncActivities/lemon-dataset/data/lemon-dataset.zip -d Examples/AsyncActivities/lemon-dataset/data/")
            return
        }

        print("🍋 Lemon Quality Control - Async Activities Example")
        print(String(repeating: "=", count: 70))
        print()

        // Get sample images from the dataset
        let imagesPath = "\(datasetPath)/images"
        let allImages = try FileManager.default.contentsOfDirectory(atPath: imagesPath)
            .filter { $0.hasSuffix(".jpg") }
            .sorted()

        // Use first 15 images for the demo
        let sampleImages = Array(allImages.prefix(15))

        print("📊 Dataset Information:")
        print("  Total images in dataset: \(allImages.count)")
        print("  Images for this demo: \(sampleImages.count)")
        print("  Dataset path: \(datasetPath)")
        print()

        // Create worker configuration
        let workerConfiguration = TemporalWorker.Configuration(
            namespace: namespace,
            taskQueue: taskQueue,
            instrumentation: .init(serverHostname: "localhost")
        )

        // Create activities
        let activities = LemonQualityActivities(datasetPath: datasetPath)

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
                workflows: [LemonQualityWorkflow.self],  // All workers can handle workflows
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
            try await Task.sleep(for: .seconds(1))

            print()
            print(String(repeating: "=", count: 70))
            print()

            // Run sequential processing first
            print("⏳ Test 1: Sequential Processing")
            print(String(repeating: "-", count: 70))
            let sequentialBatchId = "BATCH-SEQ-\(UUID().uuidString.prefix(8))"
            let sequentialRequest = LemonQualityWorkflow.BatchRequest(
                batchId: sequentialBatchId,
                imageIds: Array(sampleImages.prefix(15)),  // Process 15 images sequentially
                mode: .sequential
            )

            print("🔗 View in Temporal UI:")
            print("  http://localhost:8233/namespaces/\(namespace)/workflows/\(sequentialBatchId)")
            print()

            let sequentialStart = Date()
            let sequentialResult = try await client.executeWorkflow(
                type: LemonQualityWorkflow.self,
                options: .init(id: sequentialBatchId, taskQueue: taskQueue),
                input: sequentialRequest
            )
            let sequentialDuration = Date().timeIntervalSince(sequentialStart)

            print()
            print("✅ Sequential Processing Complete:")
            print("  Success: \(sequentialResult.successCount)/\(sequentialRequest.imageIds.count)")
            print("  Total time: \(String(format: "%.2f", sequentialDuration))s")
            print("  Average per image: \(String(format: "%.2f", sequentialDuration / Double(sequentialRequest.imageIds.count)))s")
            print()

            // Display sample results
            if !sequentialResult.reports.isEmpty {
                print("  Sample Results:")
                for report in sequentialResult.reports.prefix(3) {
                    print("    • \(report.fileName): Grade \(report.overallGrade), Quality: \(String(format: "%.1f", report.qualityScore))")
                }
                print()
            }

            // Run parallel processing
            print(String(repeating: "=", count: 70))
            print()
            print("⚡ Test 2: Parallel Processing")
            print(String(repeating: "-", count: 70))
            let parallelBatchId = "BATCH-PAR-\(UUID().uuidString.prefix(8))"
            let parallelRequest = LemonQualityWorkflow.BatchRequest(
                batchId: parallelBatchId,
                imageIds: Array(sampleImages.prefix(15)),  // Process 15 images in parallel
                mode: .parallel
            )

            print("🔗 View in Temporal UI:")
            print("  http://localhost:8233/namespaces/\(namespace)/workflows/\(parallelBatchId)")
            print()
            print("📊 Processing \(parallelRequest.imageIds.count) images in parallel...")
            print()

            let parallelStart = Date()
            let parallelResult = try await client.executeWorkflow(
                type: LemonQualityWorkflow.self,
                options: .init(id: parallelBatchId, taskQueue: taskQueue),
                input: parallelRequest
            )
            let parallelDuration = Date().timeIntervalSince(parallelStart)

            print()
            print("✅ Parallel Processing Complete:")
            print("  Success: \(parallelResult.successCount)/\(parallelRequest.imageIds.count)")
            print("  Total time: \(String(format: "%.2f", parallelDuration))s")
            print("  Average per image: \(String(format: "%.2f", parallelDuration / Double(parallelRequest.imageIds.count)))s")
            print()

            // Display sample results
            if !parallelResult.reports.isEmpty {
                print("  Sample Results:")
                for report in parallelResult.reports.prefix(5) {
                    print("    • \(report.fileName): Grade \(report.overallGrade), Quality: \(String(format: "%.1f", report.qualityScore)), \(report.hasDefects ? "⚠️ Defects" : "✅ Clean")")
                }
                print()
            }

            // Performance comparison
            print(String(repeating: "=", count: 70))
            print()
            print("📈 Performance Summary:")
            print(String(repeating: "-", count: 70))
            print("  Sequential: \(String(format: "%.2f", sequentialDuration))s for 15 images")
            print("  Parallel:   \(String(format: "%.2f", parallelDuration))s for 15 images")
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
        #if !GRPCNIOTransport
        fatalError("GRPCNIOTransport trait disabled")
        #elseif !canImport(Vision)
        fatalError("Vision framework not available on this platform")
        #endif
    }
}
#endif
