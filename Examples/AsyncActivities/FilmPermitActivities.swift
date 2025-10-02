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

/// Activities for processing NYC film permits.
@ActivityContainer
public struct FilmPermitActivities {
    // MARK: - Data Models

    public struct FilmPermit: Codable, Sendable {
        let eventId: String
        let eventType: String
        let startDateTime: String
        let endDateTime: String?
        let eventAgency: String
        let parkingHeld: String
        let borough: String
        let category: String
        let subcategoryName: String?
        let zipCode: String?
        let policePrecinct: String?

        enum CodingKeys: String, CodingKey {
            case eventId = "eventid"
            case eventType = "eventtype"
            case startDateTime = "startdatetime"
            case endDateTime = "enddatetime"
            case eventAgency = "eventagency"
            case parkingHeld = "parkingheld"
            case borough
            case category
            case subcategoryName = "subcategoryname"
            case zipCode = "zipcode_s"
            case policePrecinct = "policeprecinct_s"
        }
    }

    public struct ValidationResult: Codable, Sendable {
        let permitId: String
        let isValid: Bool
        let issues: [String]
    }

    public struct LocationAnalysis: Codable, Sendable {
        let permitId: String
        let borough: String
        let precinct: String?
        let zipCode: String?
        let locationDescription: String
        let estimatedStreetCount: Int
    }

    public struct PermitCategory: Codable, Sendable {
        let permitId: String
        let category: String
        let subcategory: String
        let eventType: String
        let isCommercial: Bool
    }

    public struct PermitAnalysis: Codable, Sendable {
        let permit: FilmPermit
        let validation: ValidationResult
        let location: LocationAnalysis
        let category: PermitCategory
        let processingTimeMs: Double
    }

    public struct AnalyticsReport: Codable, Sendable {
        let totalPermits: Int
        let validPermits: Int
        let byBorough: [String: Int]
        let byCategory: [String: Int]
        let topLocations: [String]
        let processingTimeMs: Double
    }

    // MARK: - Activities

    /// Fetches film permits from NYC Open Data API.
    @Activity
    func fetchFilmPermits(input: Int) async throws -> [FilmPermit] {
        let context = ActivityExecutionContext.current!
        let workerId = ProcessInfo.processInfo.processIdentifier

        print("📥 [Worker \(workerId)] Fetching \(input) film permits from NYC API...")

        let url = URL(string: "https://data.cityofnewyork.us/resource/tg4x-b46p.json?$limit=\(input)")!
        var request = URLRequest(url: url)
        request.timeoutInterval = 30
        request.httpMethod = "GET"

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw ApplicationError(message: "Invalid response type", type: "NetworkError")
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                throw ApplicationError(
                    message: "HTTP \(httpResponse.statusCode)",
                    type: "HTTPError",
                    isNonRetryable: httpResponse.statusCode == 404
                )
            }

            let decoder = JSONDecoder()
            let permits = try decoder.decode([FilmPermit].self, from: data)

            context.heartbeat()
            print("✅ [Worker \(workerId)] Fetched \(permits.count) permits")

            return permits

        } catch let error as URLError {
            throw ApplicationError(
                message: "Network error: \(error.localizedDescription)",
                type: "NetworkError"
            )
        } catch let error as DecodingError {
            throw ApplicationError(
                message: "Failed to parse API response: \(error)",
                type: "DecodingError"
            )
        }
    }

    /// Validates permit data quality.
    @Activity
    func validatePermit(input: FilmPermit) async throws -> ValidationResult {
        let workerId = ProcessInfo.processInfo.processIdentifier
        print("✓ [Worker \(workerId)] Validating permit \(input.eventId)")

        var issues: [String] = []

        // Check required fields
        if input.eventId.isEmpty {
            issues.append("Missing event ID")
        }
        if input.borough.isEmpty {
            issues.append("Missing borough")
        }
        if input.parkingHeld.isEmpty {
            issues.append("Missing location")
        }

        // Validate date format
        if !input.startDateTime.contains("T") {
            issues.append("Invalid date format")
        }

        let isValid = issues.isEmpty
        return ValidationResult(
            permitId: input.eventId,
            isValid: isValid,
            issues: issues
        )
    }

    /// Analyzes permit location details.
    @Activity
    func analyzeLocation(input: FilmPermit) async throws -> LocationAnalysis {
        let workerId = ProcessInfo.processInfo.processIdentifier
        print("📍 [Worker \(workerId)] Analyzing location for permit \(input.eventId)")

        // Count street segments (rough estimate based on "between" mentions)
        let locationLower = input.parkingHeld.lowercased()
        let streetCount = locationLower.components(separatedBy: "between").count - 1 + 1

        return LocationAnalysis(
            permitId: input.eventId,
            borough: input.borough,
            precinct: input.policePrecinct,
            zipCode: input.zipCode,
            locationDescription: input.parkingHeld,
            estimatedStreetCount: streetCount
        )
    }

    /// Categorizes permit by type.
    @Activity
    func categorizePermit(input: FilmPermit) async throws -> PermitCategory {
        let workerId = ProcessInfo.processInfo.processIdentifier
        print("🎬 [Worker \(workerId)] Categorizing permit \(input.eventId)")

        let commercialCategories = ["Commercial", "Advertisement", "Still Photography"]
        let isCommercial = commercialCategories.contains(input.category)

        return PermitCategory(
            permitId: input.eventId,
            category: input.category,
            subcategory: input.subcategoryName ?? "Unknown",
            eventType: input.eventType,
            isCommercial: isCommercial
        )
    }

    /// Generates analytics report from permit analyses.
    @Activity
    func generateAnalyticsReport(input: [PermitAnalysis]) async throws -> AnalyticsReport {
        let workerId = ProcessInfo.processInfo.processIdentifier
        print("📊 [Worker \(workerId)] Generating analytics report from \(input.count) permits")

        let startTime = Date()

        let validPermits = input.filter { $0.validation.isValid }.count

        // Count by borough
        var boroughCounts: [String: Int] = [:]
        for analysis in input {
            boroughCounts[analysis.permit.borough, default: 0] += 1
        }

        // Count by category
        var categoryCounts: [String: Int] = [:]
        for analysis in input {
            categoryCounts[analysis.permit.category, default: 0] += 1
        }

        // Top locations (first 5 unique boroughs)
        let topLocations = Array(Set(input.map { $0.permit.borough })).prefix(5).map { String($0) }

        let processingTime = Date().timeIntervalSince(startTime) * 1000

        return AnalyticsReport(
            totalPermits: input.count,
            validPermits: validPermits,
            byBorough: boroughCounts,
            byCategory: categoryCounts,
            topLocations: topLocations,
            processingTimeMs: processingTime
        )
    }
}
