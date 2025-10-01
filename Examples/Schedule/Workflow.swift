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

@Workflow
final class SpaceMissionWorkflow {
    func run(input: MissionOperationInput) async throws -> MissionOperationResult {
        let startTime = Date()

        let activityOptions = ActivityOptions(
            startToCloseTimeout: .seconds(30),
            retryPolicy: RetryPolicy(
                initialInterval: .seconds(1),
                maximumAttempts: 3
            )
        )

        do {
            switch input.operation {
            case .collectTelemetry:
                let telemetry = try await Workflow.executeActivity(
                    SpaceMissionActivities.Activities.CollectRealTelemetry.self,
                    options: activityOptions,
                    input: TelemetryRequest()
                )
                return MissionOperationResult(
                    operation: .collectTelemetry,
                    status: .success,
                    telemetryData: telemetry,
                    duration: Date().timeIntervalSince(startTime),
                    timestamp: Date()
                )

            case .checkCrew:
                let crew = try await Workflow.executeActivity(
                    SpaceMissionActivities.Activities.CheckCrewStatus.self,
                    options: activityOptions,
                    input: CrewStatusRequest(filterCraft: "ISS")
                )
                return MissionOperationResult(
                    operation: .checkCrew,
                    status: .success,
                    crewStatus: crew,
                    duration: Date().timeIntervalSince(startTime),
                    timestamp: Date()
                )

            case .systemHealth:
                let health = try await Workflow.executeActivity(
                    SpaceMissionActivities.Activities.PerformSystemHealthCheck.self,
                    options: activityOptions,
                    input: HealthCheckRequest(priority: input.priority)
                )
                return MissionOperationResult(
                    operation: .systemHealth,
                    status: .success,
                    healthCheck: health,
                    duration: Date().timeIntervalSince(startTime),
                    timestamp: Date()
                )

            case .orbitCorrection:
                // First get current telemetry
                let telemetry = try await Workflow.executeActivity(
                    SpaceMissionActivities.Activities.CollectRealTelemetry.self,
                    options: activityOptions,
                    input: TelemetryRequest()
                )

                // Determine if correction needed
                let targetAltitude = 410.0  // km
                let needsCorrection = abs(telemetry.altitude - targetAltitude) > 5.0

                if needsCorrection {
                    // Simulate thruster burn duration
                    let burnDuration = 45
                    try await Workflow.sleep(for: .seconds(burnDuration))

                    // Execute correction
                    let correction = try await Workflow.executeActivity(
                        SpaceMissionActivities.Activities.ExecuteOrbitCorrection.self,
                        options: activityOptions,
                        input: OrbitCorrectionInput(
                            currentAltitude: telemetry.altitude,
                            targetAltitude: targetAltitude,
                            burnDuration: burnDuration
                        )
                    )

                    return MissionOperationResult(
                        operation: .orbitCorrection,
                        status: .success,
                        telemetryData: telemetry,
                        orbitCorrection: correction,
                        duration: Date().timeIntervalSince(startTime),
                        timestamp: Date()
                    )
                } else {
                    return MissionOperationResult(
                        operation: .orbitCorrection,
                        status: .success,
                        telemetryData: telemetry,
                        duration: Date().timeIntervalSince(startTime),
                        timestamp: Date(),
                        errorMessage: "No correction needed, altitude within tolerance"
                    )
                }

            case .generateReport:
                let report = try await Workflow.executeActivity(
                    SpaceMissionActivities.Activities.GenerateMissionReport.self,
                    options: activityOptions,
                    input: ReportRequest(includeHistory: false)
                )
                return MissionOperationResult(
                    operation: .generateReport,
                    status: .success,
                    report: report,
                    duration: Date().timeIntervalSince(startTime),
                    timestamp: Date()
                )
            }
        } catch {
            return MissionOperationResult(
                operation: input.operation,
                status: .failed,
                duration: Date().timeIntervalSince(startTime),
                timestamp: Date(),
                errorMessage: error.localizedDescription
            )
        }
    }
}
