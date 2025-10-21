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

import Foundation
import Temporal

/// Workflow for processing NYC film permits with parallel and sequential modes.
@Workflow
final class FilmPermitWorkflow {
    enum ProcessingMode: String, Codable, Sendable {
        case sequential
        case parallel
    }

    struct BatchRequest: Codable, Sendable {
        let permits: [FilmPermitActivities.FilmPermit]
        let mode: ProcessingMode
    }

    struct BatchResult: Codable, Sendable {
        let report: FilmPermitActivities.AnalyticsReport
        let processingTimeMs: Double
    }

    func run(input: BatchRequest) async throws -> BatchResult {
        let startTime = Date()

        // Process permits based on mode (permits already fetched)
        var analyses: [FilmPermitActivities.PermitAnalysis] = []

        if input.mode == .sequential {
            // Sequential processing
            for permit in input.permits {
                let analysis = try await processPermit(permit: permit)
                analyses.append(analysis)
            }
        } else {
            // Parallel processing with task group
            try await withThrowingTaskGroup(of: FilmPermitActivities.PermitAnalysis.self) { group in
                for permit in input.permits {
                    group.addTask {
                        try await self.processPermit(permit: permit)
                    }
                }

                for try await analysis in group {
                    analyses.append(analysis)
                }
            }
        }

        // Generate analytics report
        let report = try await Workflow.executeActivity(
            FilmPermitActivities.Activities.GenerateAnalyticsReport.self,
            options: ActivityOptions(
                startToCloseTimeout: .seconds(10)
            ),
            input: analyses
        )

        let totalTime = Date().timeIntervalSince(startTime) * 1000

        return BatchResult(
            report: report,
            processingTimeMs: totalTime
        )
    }

    /// Process a single permit through validation, location analysis, and categorization.
    private func processPermit(permit: FilmPermitActivities.FilmPermit) async throws -> FilmPermitActivities.PermitAnalysis {
        let permitStart = Date()

        // Run three analyses in parallel using async let
        async let validation = Workflow.executeActivity(
            FilmPermitActivities.Activities.ValidatePermit.self,
            options: ActivityOptions(startToCloseTimeout: .seconds(5)),
            input: permit
        )

        async let location = Workflow.executeActivity(
            FilmPermitActivities.Activities.AnalyzeLocation.self,
            options: ActivityOptions(startToCloseTimeout: .seconds(5)),
            input: permit
        )

        async let category = Workflow.executeActivity(
            FilmPermitActivities.Activities.CategorizePermit.self,
            options: ActivityOptions(startToCloseTimeout: .seconds(5)),
            input: permit
        )

        let (validationResult, locationResult, categoryResult) = try await (validation, location, category)

        let processingTime = Date().timeIntervalSince(permitStart) * 1000

        return FilmPermitActivities.PermitAnalysis(
            permit: permit,
            validation: validationResult,
            location: locationResult,
            category: categoryResult,
            processingTimeMs: processingTime
        )
    }
}
