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
struct MultipleActivitiesActivities {
    private let databaseClient: DatabaseClient

    init(databaseClient: DatabaseClient) {
        self.databaseClient = databaseClient
    }

    init() {
        self.databaseClient = FakeDatabaseClient()
    }

    @Activity
    func composeGreeting(input: String) async throws -> String {
        // Fetch greeting template from database
        let greetingTemplate = try await databaseClient.fetchData(forKey: "greeting")
        return "\(greetingTemplate), \(input)!"
    }

    @Activity
    func fetchUserData(input: String) async throws -> String {
        // Fetch user data from database
        let userData = try await databaseClient.fetchData(forKey: input)
        return userData
    }

    @Activity
    func addExclamation(input: String) -> String {
        return "\(input)!!!"
    }

    @Activity
    func addQuestion(input: String) -> String {
        return "\(input)???"
    }

    @Activity
    func toUpperCase(input: String) -> String {
        return input.uppercased()
    }

    @Activity
    func addPrefix(input: String) async throws -> String {
        // Fetch prefix from database
        let prefix = try await databaseClient.fetchData(forKey: "prefix")
        return "\(prefix): \(input)"
    }

    @Activity
    func saveResult(input: String) async throws -> String {
        // Save the final result to database
        let key = "result_\(UUID().uuidString.prefix(8))"
        try await databaseClient.saveData(input, forKey: key)
        return "Result saved with key: \(key)"
    }
}
