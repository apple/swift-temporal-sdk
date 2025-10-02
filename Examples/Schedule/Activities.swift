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

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

// MARK: - API Response Models

private struct ISSPositionResponse: Codable {
    let name: String
    let id: Int
    let latitude: Double
    let longitude: Double
    let altitude: Double
    let velocity: Double
    let visibility: String
    let footprint: Double
    let timestamp: Int
}

private struct AstronautInfo: Codable {
    let name: String
    let craft: String
}

private struct AstronautsResponse: Codable {
    let people: [AstronautInfo]
    let number: Int
    let message: String
}

// MARK: - Activity Errors

enum SpaceAPIError: Error, CustomStringConvertible {
    case networkError(String)
    case invalidResponse
    case decodingError(String)
    case apiError(String)

    var description: String {
        switch self {
        case .networkError(let message):
            return "Network error: \(message)"
        case .invalidResponse:
            return "Invalid response from API"
        case .decodingError(let message):
            return "Failed to decode response: \(message)"
        case .apiError(let message):
            return "API error: \(message)"
        }
    }
}

// MARK: - Activities

@ActivityContainer
struct SpaceMissionActivities {
    @Activity
    func collectRealTelemetry(input: TelemetryRequest) async throws -> TelemetryData {
        let urlString = "https://api.wheretheiss.at/v1/satellites/\(input.satelliteId)"
        guard let url = URL(string: urlString) else {
            throw SpaceAPIError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 30

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw SpaceAPIError.invalidResponse
            }

            guard httpResponse.statusCode == 200 else {
                throw SpaceAPIError.apiError("HTTP \(httpResponse.statusCode)")
            }

            let decoder = JSONDecoder()
            let issResponse = try decoder.decode(ISSPositionResponse.self, from: data)

            return TelemetryData(
                latitude: issResponse.latitude,
                longitude: issResponse.longitude,
                altitude: issResponse.altitude,
                velocity: issResponse.velocity,
                visibility: issResponse.visibility,
                footprint: issResponse.footprint,
                timestamp: issResponse.timestamp
            )
        } catch let error as DecodingError {
            throw SpaceAPIError.decodingError(error.localizedDescription)
        } catch let error as SpaceAPIError {
            throw error
        } catch {
            throw SpaceAPIError.networkError(error.localizedDescription)
        }
    }

    @Activity
    func checkCrewStatus(input: CrewStatusRequest) async throws -> CrewStatus {
        let urlString = "http://api.open-notify.org/astros.json"
        guard let url = URL(string: urlString) else {
            throw SpaceAPIError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 30

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw SpaceAPIError.invalidResponse
            }

            guard httpResponse.statusCode == 200 else {
                throw SpaceAPIError.apiError("HTTP \(httpResponse.statusCode)")
            }

            let decoder = JSONDecoder()
            let astronautsResponse = try decoder.decode(AstronautsResponse.self, from: data)

            // Separate ISS crew from other stations
            let issCrew = astronautsResponse.people.filter { $0.craft == "ISS" }
            let otherCrew = astronautsResponse.people.filter { $0.craft != "ISS" }

            var otherStations: [String: [String]] = [:]
            for person in otherCrew {
                if otherStations[person.craft] == nil {
                    otherStations[person.craft] = []
                }
                otherStations[person.craft]?.append(person.name)
            }

            return CrewStatus(
                totalInSpace: astronautsResponse.number,
                issCrewCount: issCrew.count,
                issCrewMembers: issCrew.map { $0.name },
                otherStations: otherStations,
                timestamp: Date()
            )
        } catch let error as DecodingError {
            throw SpaceAPIError.decodingError(error.localizedDescription)
        } catch let error as SpaceAPIError {
            throw error
        } catch {
            throw SpaceAPIError.networkError(error.localizedDescription)
        }
    }

    @Activity
    func performSystemHealthCheck(input: HealthCheckRequest) async throws -> HealthCheckResult {
        // Get real telemetry to assess orbital parameters
        let telemetry = try await collectRealTelemetry(input: TelemetryRequest())

        // Simulate subsystem checks with some randomness
        let dataStorage = Double.random(in: 75...95)
        let temperature = Double.random(in: 20...24)

        // Assess orbital parameters based on real data
        let altitudeInRange = telemetry.altitude >= 400 && telemetry.altitude <= 420
        let velocityInRange = telemetry.velocity >= 27400 && telemetry.velocity <= 27700

        let orbitalStatus: String
        if altitudeInRange && velocityInRange {
            orbitalStatus = "Nominal"
        } else if !altitudeInRange {
            orbitalStatus = "Altitude deviation detected"
        } else {
            orbitalStatus = "Velocity deviation detected"
        }

        let overallStatus: String
        if dataStorage < 80 || !altitudeInRange || !velocityInRange {
            overallStatus = "Attention required"
        } else {
            overallStatus = "All systems operational"
        }

        return HealthCheckResult(
            dataStorageAvailable: dataStorage,
            powerSystemsStatus: "Nominal (Solar arrays optimal)",
            thermalControlTemp: temperature,
            communicationsStatus: "All ground station links active",
            orbitalParametersStatus: orbitalStatus,
            overallStatus: overallStatus,
            timestamp: Date()
        )
    }

    @Activity
    func executeOrbitCorrection(input: OrbitCorrectionInput) async throws -> OrbitCorrectionResult {
        // Calculate required delta-v (simplified)
        let altitudeDiff = input.targetAltitude - input.currentAltitude
        let deltaV = abs(altitudeDiff) * 0.001  // Simplified calculation

        // Simulate fuel usage
        let fuelUsed = deltaV * 100  // kg

        return OrbitCorrectionResult(
            success: true,
            deltaV: deltaV,
            newAltitude: input.targetAltitude,
            fuelUsed: fuelUsed,
            timestamp: Date()
        )
    }

    @Activity
    func generateMissionReport(input: ReportRequest) async throws -> MissionReport {
        // Gather current data
        let telemetry = try await collectRealTelemetry(input: TelemetryRequest())
        let crew = try await checkCrewStatus(input: CrewStatusRequest(filterCraft: "ISS"))
        let health = try await performSystemHealthCheck(input: HealthCheckRequest())

        let reportId = "REPORT-\(UUID().uuidString.prefix(8))"

        let telemetrySummary = """
            Position: \(telemetry.formattedPosition)
            Altitude: \(String(format: "%.2f", telemetry.altitude)) km (\(telemetry.altitudeStatus))
            Velocity: \(String(format: "%.2f", telemetry.velocity)) km/h
            """

        let crewSummary = """
            ISS Crew: \(crew.issCrewCount) astronauts
            Total in space: \(crew.totalInSpace)
            """

        let healthSummary = """
            Overall: \(health.overallStatus)
            Storage: \(String(format: "%.1f", health.dataStorageAvailable))% available
            Orbital: \(health.orbitalParametersStatus)
            """

        return MissionReport(
            reportId: reportId,
            generatedAt: Date(),
            telemetrySummary: telemetrySummary,
            crewSummary: crewSummary,
            healthSummary: healthSummary
        )
    }
}
