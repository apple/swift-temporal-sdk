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

// MARK: - Operation Types

enum OperationType: String, Codable, Sendable {
    case collectTelemetry
    case checkCrew
    case systemHealth
    case orbitCorrection
    case generateReport
}

enum Priority: String, Codable, Sendable {
    case routine
    case elevated
    case critical
}

enum OperationStatus: String, Codable, Sendable {
    case success
    case failed
    case partial
}

// MARK: - Request Types

struct TelemetryRequest: Codable, Sendable {
    var missionTime: Int
    var satelliteId: Int = 25544  // ISS NORAD catalog ID

    init(missionTime: Int = 0, satelliteId: Int = 25544) {
        self.missionTime = missionTime
        self.satelliteId = satelliteId
    }
}

struct CrewStatusRequest: Codable, Sendable {
    var filterCraft: String?

    init(filterCraft: String? = nil) {
        self.filterCraft = filterCraft
    }
}

struct HealthCheckRequest: Codable, Sendable {
    var priority: Priority

    init(priority: Priority = .routine) {
        self.priority = priority
    }
}

struct OrbitCorrectionInput: Codable, Sendable {
    var currentAltitude: Double
    var targetAltitude: Double
    var burnDuration: Int  // seconds

    init(currentAltitude: Double, targetAltitude: Double, burnDuration: Int) {
        self.currentAltitude = currentAltitude
        self.targetAltitude = targetAltitude
        self.burnDuration = burnDuration
    }
}

struct ReportRequest: Codable, Sendable {
    var includeHistory: Bool

    init(includeHistory: Bool = false) {
        self.includeHistory = includeHistory
    }
}

struct MissionOperationInput: Codable, Sendable {
    var operation: OperationType
    var priority: Priority

    init(operation: OperationType, priority: Priority = .routine) {
        self.operation = operation
        self.priority = priority
    }
}

// MARK: - Response Types

struct TelemetryData: Codable, Sendable {
    // Real data from wheretheiss.at API
    var latitude: Double
    var longitude: Double
    var altitude: Double  // km
    var velocity: Double  // km/h
    var visibility: String  // "daylight" or "eclipsed"
    var footprint: Double  // km diameter
    var timestamp: Int  // Unix timestamp

    // Human-readable additions
    var formattedPosition: String
    var altitudeStatus: String

    init(
        latitude: Double,
        longitude: Double,
        altitude: Double,
        velocity: Double,
        visibility: String,
        footprint: Double,
        timestamp: Int
    ) {
        self.latitude = latitude
        self.longitude = longitude
        self.altitude = altitude
        self.velocity = velocity
        self.visibility = visibility
        self.footprint = footprint
        self.timestamp = timestamp

        // Format position
        let latDir = latitude >= 0 ? "N" : "S"
        let lonDir = longitude >= 0 ? "E" : "W"
        self.formattedPosition = String(format: "%.2f°%@, %.2f°%@", abs(latitude), latDir, abs(longitude), lonDir)

        // Check altitude status (nominal range: 400-420 km)
        if altitude >= 400 && altitude <= 420 {
            self.altitudeStatus = "Nominal"
        } else if altitude < 400 {
            self.altitudeStatus = "Low"
        } else {
            self.altitudeStatus = "High"
        }
    }
}

struct CrewStatus: Codable, Sendable {
    var totalInSpace: Int
    var issCrewCount: Int
    var issCrewMembers: [String]
    var otherStations: [String: [String]]
    var timestamp: Date

    init(
        totalInSpace: Int,
        issCrewCount: Int,
        issCrewMembers: [String],
        otherStations: [String: [String]],
        timestamp: Date
    ) {
        self.totalInSpace = totalInSpace
        self.issCrewCount = issCrewCount
        self.issCrewMembers = issCrewMembers
        self.otherStations = otherStations
        self.timestamp = timestamp
    }
}

struct HealthCheckResult: Codable, Sendable {
    var dataStorageAvailable: Double  // percentage
    var powerSystemsStatus: String
    var thermalControlTemp: Double  // Celsius
    var communicationsStatus: String
    var orbitalParametersStatus: String
    var overallStatus: String
    var timestamp: Date

    init(
        dataStorageAvailable: Double,
        powerSystemsStatus: String,
        thermalControlTemp: Double,
        communicationsStatus: String,
        orbitalParametersStatus: String,
        overallStatus: String,
        timestamp: Date
    ) {
        self.dataStorageAvailable = dataStorageAvailable
        self.powerSystemsStatus = powerSystemsStatus
        self.thermalControlTemp = thermalControlTemp
        self.communicationsStatus = communicationsStatus
        self.orbitalParametersStatus = orbitalParametersStatus
        self.overallStatus = overallStatus
        self.timestamp = timestamp
    }
}

struct OrbitCorrectionResult: Codable, Sendable {
    var success: Bool
    var deltaV: Double  // km/s
    var newAltitude: Double  // km
    var fuelUsed: Double  // kg
    var timestamp: Date

    init(success: Bool, deltaV: Double, newAltitude: Double, fuelUsed: Double, timestamp: Date) {
        self.success = success
        self.deltaV = deltaV
        self.newAltitude = newAltitude
        self.fuelUsed = fuelUsed
        self.timestamp = timestamp
    }
}

struct MissionReport: Codable, Sendable {
    var reportId: String
    var generatedAt: Date
    var telemetrySummary: String
    var crewSummary: String
    var healthSummary: String

    init(reportId: String, generatedAt: Date, telemetrySummary: String, crewSummary: String, healthSummary: String) {
        self.reportId = reportId
        self.generatedAt = generatedAt
        self.telemetrySummary = telemetrySummary
        self.crewSummary = crewSummary
        self.healthSummary = healthSummary
    }
}

struct MissionOperationResult: Codable, Sendable {
    var operation: OperationType
    var status: OperationStatus
    var telemetryData: TelemetryData?
    var crewStatus: CrewStatus?
    var healthCheck: HealthCheckResult?
    var orbitCorrection: OrbitCorrectionResult?
    var report: MissionReport?
    var duration: TimeInterval
    var timestamp: Date
    var errorMessage: String?

    init(
        operation: OperationType,
        status: OperationStatus,
        telemetryData: TelemetryData? = nil,
        crewStatus: CrewStatus? = nil,
        healthCheck: HealthCheckResult? = nil,
        orbitCorrection: OrbitCorrectionResult? = nil,
        report: MissionReport? = nil,
        duration: TimeInterval,
        timestamp: Date,
        errorMessage: String? = nil
    ) {
        self.operation = operation
        self.status = status
        self.telemetryData = telemetryData
        self.crewStatus = crewStatus
        self.healthCheck = healthCheck
        self.orbitCorrection = orbitCorrection
        self.report = report
        self.duration = duration
        self.timestamp = timestamp
        self.errorMessage = errorMessage
    }
}
