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

import Temporal

/// Demonstrates parallel/concurrent activity execution in Temporal workflows.
/// This workflow processes lemon images for quality control using multiple concurrent patterns:
/// - Processing multiple images in parallel using task groups
/// - Running multiple analysis activities concurrently per image using async let
/// - Distributing work across multiple workers
@Workflow
public final class LemonQualityWorkflow {
    public struct BatchRequest: Codable, Sendable {
        let batchId: String
        let imageIds: [String]
        let mode: ProcessingMode

        init(batchId: String, imageIds: [String], mode: ProcessingMode) {
            self.batchId = batchId
            self.imageIds = imageIds
            self.mode = mode
        }
    }

    public enum ProcessingMode: String, Codable, Sendable {
        case sequential
        case parallel
    }

    public struct BatchResult: Codable, Sendable {
        let batchId: String
        let reports: [LemonQualityActivities.QualityReport]
        let totalProcessingTime: Double
        let successCount: Int
        let failureCount: Int
    }


    public func run(input: BatchRequest) async throws -> BatchResult {
        let startTime = Workflow.now

        var reports: [LemonQualityActivities.QualityReport] = []
        var successCount = 0
        var failureCount = 0

        if input.mode == .sequential {
            // Sequential processing - one image at a time
            for imageId in input.imageIds {
                do {
                    let report = try await processImage(imageId: imageId)
                    reports.append(report)
                    successCount += 1
                } catch {
                    failureCount += 1
                    // Continue processing other images even if one fails
                }
            }
        } else {
            // Parallel processing - all images concurrently
            try await withThrowingTaskGroup(of: LemonQualityActivities.QualityReport?.self) { group in
                // Add a task for each image to process
                for imageId in input.imageIds {
                    group.addTask {
                        do {
                            return try await self.processImage(imageId: imageId)
                        } catch {
                            // Return nil for failed images
                            return nil
                        }
                    }
                }

                // Collect results as they complete
                for try await result in group {
                    if let report = result {
                        reports.append(report)
                        successCount += 1
                    } else {
                        failureCount += 1
                    }
                }
            }
        }

        let endTime = Workflow.now
        let totalProcessingTime = endTime.timeIntervalSince(startTime)

        return BatchResult(
            batchId: input.batchId,
            reports: reports,
            totalProcessingTime: totalProcessingTime,
            successCount: successCount,
            failureCount: failureCount
        )
    }

    /// Processes a single image by running multiple analysis activities in parallel
    private func processImage(imageId: String) async throws -> LemonQualityActivities.QualityReport {
        let imageStartTime = Workflow.now

        // Step 1: Fetch image metadata first
        let metadata = try await Workflow.executeActivity(
            LemonQualityActivities.Activities.FetchImageMetadata.self,
            options: .init(
                startToCloseTimeout: .seconds(10),
                retryPolicy: .init(
                    initialInterval: .milliseconds(500),
                    maximumAttempts: 3
                )
            ),
            input: imageId
        )

        // Step 2: Run three analysis activities in parallel using async let
        // This demonstrates concurrent execution within a single workflow
        async let qualityResult = Workflow.executeActivity(
            LemonQualityActivities.Activities.AnalyzeImageQuality.self,
            options: .init(
                startToCloseTimeout: .seconds(30),
                retryPolicy: .init(
                    initialInterval: .seconds(1),
                    maximumAttempts: 3
                )
            ),
            input: metadata
        )

        async let defectsResult = Workflow.executeActivity(
            LemonQualityActivities.Activities.DetectDefects.self,
            options: .init(
                startToCloseTimeout: .seconds(30),
                retryPolicy: .init(
                    initialInterval: .seconds(1),
                    maximumAttempts: 3
                )
            ),
            input: metadata
        )

        async let attributesResult = Workflow.executeActivity(
            LemonQualityActivities.Activities.CheckQualityAttributes.self,
            options: .init(
                startToCloseTimeout: .seconds(30),
                retryPolicy: .init(
                    initialInterval: .seconds(1),
                    maximumAttempts: 3
                )
            ),
            input: metadata
        )

        // Wait for all three activities to complete
        let (quality, defects, attributes) = try await (qualityResult, defectsResult, attributesResult)

        // Step 3: Generate final report
        let reportInput = LemonQualityActivities.GenerateReportInput(
            metadata: metadata,
            quality: quality,
            defects: defects,
            attributes: attributes
        )

        var report = try await Workflow.executeActivity(
            LemonQualityActivities.Activities.GenerateQualityReport.self,
            options: .init(
                startToCloseTimeout: .seconds(10),
                retryPolicy: .init(
                    initialInterval: .milliseconds(500),
                    maximumAttempts: 3
                )
            ),
            input: reportInput
        )

        let imageEndTime = Workflow.now
        let processingTime = imageEndTime.timeIntervalSince(imageStartTime)

        // Update the report with actual processing time
        report = LemonQualityActivities.QualityReport(
            imageId: report.imageId,
            fileName: report.fileName,
            qualityScore: report.qualityScore,
            isBlurry: report.isBlurry,
            brightness: report.brightness,
            contrast: report.contrast,
            hasDefects: report.hasDefects,
            defectTypes: report.defectTypes,
            isHealthy: report.isHealthy,
            attributes: report.attributes,
            overallGrade: report.overallGrade,
            processingTime: processingTime
        )

        return report
    }
}
