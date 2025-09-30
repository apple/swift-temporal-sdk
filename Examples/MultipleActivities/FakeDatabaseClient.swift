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

// Protocol defining database operations
protocol DatabaseClient: Sendable {
    func fetchData(forKey key: String) async throws -> String
    func saveData(_ data: String, forKey key: String) async throws
    func deleteData(forKey key: String) async throws
}

// Fake database client implementation that simulates database operations
actor FakeDatabaseClient: DatabaseClient {
    private var storage: [String: String] = [:]

    init() {
        // Initialize with some sample data
        storage = [
            "user1": "John Doe",
            "user2": "Jane Smith",
            "user3": "Bob Johnson",
            "greeting": "Hello from database",
            "prefix": "DB_PREFIX",
        ]
    }

    func fetchData(forKey key: String) async throws -> String {
        // Simulate network delay
        try await Task.sleep(for: .milliseconds(100))

        guard let data = storage[key] else {
            throw DatabaseError.keyNotFound(key)
        }
        return data
    }

    func saveData(_ data: String, forKey key: String) async throws {
        // Simulate network delay
        try await Task.sleep(for: .milliseconds(50))
        storage[key] = data
    }

    func deleteData(forKey key: String) async throws {
        // Simulate network delay
        try await Task.sleep(for: .milliseconds(50))
        storage.removeValue(forKey: key)
    }
}

// Database error types
enum DatabaseError: Error, LocalizedError {
    case keyNotFound(String)
    case connectionFailed
    case timeout

    var errorDescription: String? {
        switch self {
        case .keyNotFound(let key):
            return "Key '\(key)' not found in database"
        case .connectionFailed:
            return "Database connection failed"
        case .timeout:
            return "Database operation timed out"
        }
    }
}
