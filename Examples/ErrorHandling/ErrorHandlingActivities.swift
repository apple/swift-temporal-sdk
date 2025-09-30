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

import Foundation
import Temporal

@ActivityContainer
struct ErrorHandlingActivities {
    // Internal in-memory DB + failure simulator moved here so activities
    // can control retry behavior without relying on an external fake client.
    private actor DBState {
        var storage: [String: String] = [
            "user1": "John Doe",
            "user2": "Jane Smith",
            "user3": "Bob Johnson",
            "greeting": "Hello from database",
            "prefix": "DB_PREFIX",
        ]

        var failureCount: [String: Int] = [:]
        let maxFailures = 3

        enum DatabaseError: Error, LocalizedError {
            case keyNotFound(String)
            case connectionFailed
            case timeout
            case serverOverloaded
            case temporaryOutage
            case networkPartition

            var errorDescription: String? {
                switch self {
                case .keyNotFound(let key):
                    return "Key '\(key)' not found in database"
                case .connectionFailed:
                    return "Database connection failed"
                case .timeout:
                    return "Database operation timed out"
                case .serverOverloaded:
                    return "Database server is overloaded"
                case .temporaryOutage:
                    return "Temporary database outage"
                case .networkPartition:
                    return "Network partition detected"
                }
            }

            var isRetryable: Bool {
                switch self {
                case .keyNotFound:
                    return false
                case .connectionFailed, .timeout, .serverOverloaded, .temporaryOutage, .networkPartition:
                    return true
                }
            }
        }

        private func simulateFailure(forKey key: String, operation: String = "unknown") throws {
            let current = failureCount[key, default: 0]
            
            // Only simulate failures for save operations, not fetch operations
            if operation.contains("save") && current < maxFailures {
                failureCount[key] = current + 1

                let error: DatabaseError
                switch current % 3 {
                case 0: error = .temporaryOutage
                case 1: error = .serverOverloaded
                case 2: error = .networkPartition
                default: error = .connectionFailed
                }

                print("Database operation failed (attempt \(current + 1)/\(maxFailures)): \(error.errorDescription ?? "Unknown error")\nTemporal will retry this operation.")
                throw error
            }

            // reset counter on success so subsequent keys start fresh
            if operation.contains("save") {
                failureCount[key] = 0
            }
        }

        nonisolated func delayFetch() async throws {
            try await Task.sleep(for: .milliseconds(100))
        }

        nonisolated func delaySave() async throws {
            try await Task.sleep(for: .milliseconds(50))
        }

        func fetchData(forKey key: String) async throws -> String {
            try await delayFetch()
            try simulateFailure(forKey: key, operation: "fetch")
            guard let value = storage[key] else {
                throw DatabaseError.keyNotFound(key)
            }
            return value
        }

        func saveData(_ data: String, forKey key: String) async throws {
            try await delaySave()
            try simulateFailure(forKey: key, operation: "save")
            storage[key] = data
        }

        func deleteData(forKey key: String) async throws {
            try await delaySave()
            try simulateFailure(forKey: key, operation: "delete")
            storage.removeValue(forKey: key)
        }
    }

    private let db = DBState()

    @Activity
    func fetchUserData(input: String) async throws -> String {
        print("🔄 Starting fetchUserData activity for key: \(input)")
        do {
            let value = try await db.fetchData(forKey: input)
            print("✅ fetchUserData completed successfully: \(value)")
            return value
        } catch let error as DBState.DatabaseError {
            if error.isRetryable {
                throw ApplicationError(
                    message: error.localizedDescription,
                    type: "TransientError",
                    isNonRetryable: false
                )
            }
            throw error
        }
    }

    @Activity
    func saveWithValidation(input: String) async throws -> String {
        print("🔄 Starting saveWithValidation activity for data: \(input)")
        // Generate a deterministic key for this save operation so retries
        // attempt the same key and the internal DB simulator can track attempts.
        let base64 = Data(input.utf8).base64EncodedString()
        let keySuffix = base64.prefix(12)
        let key = "validated_\(keySuffix)"

        // Validate data before saving (simulating business logic)
        guard !input.isEmpty else {
            print("Business logic validation failed: Cannot save empty data\nThis is a non-retryable error - Temporal will NOT retry this operation.")
            throw ApplicationError(
                message: "Cannot save empty data",
                type: "InvalidInputError",
                isNonRetryable: true  // Business logic error, don't retry
            )
        }

        do {
            try await db.saveData(input, forKey: key)
            print("✅ saveWithValidation completed successfully with key: \(key)")
            return "Data saved successfully with key: \(key)"
        } catch let error as DBState.DatabaseError {
            if error.isRetryable {
                throw ApplicationError(
                    message: error.localizedDescription,
                    type: "TransientError",
                    isNonRetryable: false
                )
            }
            throw error
        }
    }

    @Activity
    func processWithCompensation(input: String) async throws -> String {
        let tempKey = "temp_\(UUID().uuidString.prefix(8))"

        do {
            // First operation - might fail
            try await db.saveData(input, forKey: tempKey)

            // Simulate some processing that might fail
            if input.contains("trigger_failure") {
                throw ApplicationError(
                    message: "Processing failed",
                    type: "TransientError",
                    isNonRetryable: false
                )
            }

            // If we get here, processing succeeded
            return "Processed successfully: \(input)"

        } catch {
            // Compensating action - cleanup on failure
            print("Operation failed, attempting compensation (cleanup)...")
            do {
                try await db.deleteData(forKey: tempKey)
            } catch {
                // Log compensation failure but throw original error
                print("Compensation failed: \(error.localizedDescription)")
            }
            throw error
        }
    }

    @Activity
    func updateUserProfile(input: String) async throws -> String {
        print("🔄 Starting updateUserProfile activity for data: \(input)")
        let profileKey = "profile_\(UUID().uuidString.prefix(8))"
        
        // Simulate a simple profile update that always succeeds (no database failures)
        try await Task.sleep(for: .milliseconds(50))  // Simulate processing time
        print("✅ updateUserProfile completed successfully with key: \(profileKey)")
        return "Profile updated successfully with key: \(profileKey)"
    }

    @Activity
    func rollbackUserProfile(input: String) async throws -> String {
        print("🔄 Starting rollbackUserProfile activity for key: \(input)")
        
        do {
            try await db.deleteData(forKey: input)
            print("✅ rollbackUserProfile completed successfully - deleted key: \(input)")
            return "Profile rollback completed for key: \(input)"
        } catch let error as DBState.DatabaseError {
            if error.isRetryable {
                throw ApplicationError(
                    message: error.localizedDescription,
                    type: "TransientError",
                    isNonRetryable: false
                )
            }
            throw error
        }
    }

    @Activity
    func cascadingOperation(input: String) async throws -> String {
        var result = ""

        // First operation with retries - will fail a few times then succeed
        let userData = try await fetchUserData(input: input)
        result += "1. Fetched user data after retries: \(userData)\n"

        // Second operation with validation - will fail for empty input
        let validatedData = try await saveWithValidation(input: userData)
        result += "2. Validated and saved data: \(validatedData)\n"

        // Third operation with compensation - will cleanup on failure
        let processedData = try await processWithCompensation(input: validatedData + "_trigger_failure")
        result += "3. Processed with compensation: \(processedData)\n"

        return result
    }
}
