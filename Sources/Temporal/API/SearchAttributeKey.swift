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

public import Foundation

/// A key (unique name & type) used to specify a search attribute.
///
/// Use one of the static functions (``bool(_:)``, ``date(_:)``, ``double(_:)``, etc...) to create
/// a new key.
public struct SearchAttributeKey<Value: Sendable>: Hashable, Sendable {
    let storage: SearchAttributeKeyStorage

    init(name: String, type: SearchAttributeType) {
        self.init(storage: .init(name: name, type: type))
    }

    init(storage: SearchAttributeKeyStorage) {
        self.storage = storage
    }

    /// The name of the attribute.
    public var name: String { storage.name }

    /// The type of the attribute.
    public var type: SearchAttributeType { storage.type }
}

extension SearchAttributeKey: CustomStringConvertible {
    public var description: String { name }
}

/// A type-erased ``SearchAttributeKey``.
public struct AnySearchAttributeKey: Hashable, Sendable {
    let storage: SearchAttributeKeyStorage
    init(_ storage: SearchAttributeKeyStorage) {
        self.storage = storage
    }

    public init<Value>(_ key: SearchAttributeKey<Value>) {
        self.storage = key.storage
    }

    /// The name of the attribute.
    public var name: String { storage.name }

    /// The type of the attribute.
    public var type: SearchAttributeType { storage.type }
}
extension AnySearchAttributeKey: CustomStringConvertible {
    public var description: String { name }
}

struct SearchAttributeKeyStorage: Hashable, Sendable {
    let name: String
    let type: SearchAttributeType
}

// MARK: Define Search Attributes

extension SearchAttributeKey where Value == Bool {
    /// Creates a key for a ``SearchAttributeType/bool`` typed search attribute.
    /// - Parameter name: The name of the attribute. Must be unique across all attributes.
    public static func bool(_ name: String) -> Self { .init(name: name, type: .bool) }

    public static let temporalSchedulePaused = Self.bool("TemporalSchedulePaused")
}

extension SearchAttributeKey where Value == String {
    /// Creates a key for a ``SearchAttributeType/keyword`` typed search attribute.
    /// - Parameter name: The name of the attribute. Must be unique across all attributes.
    public static func keyword(_ name: String) -> Self { .init(name: name, type: .keyword) }

    /// Creates a key for a ``SearchAttributeType/text`` typed search attribute.
    /// - Parameter name: The name of the attribute. Must be unique across all attributes.
    public static func text(_ name: String) -> Self { .init(name: name, type: .text) }

    public static let batcherUser = Self.keyword("BatcherUser")
    public static let executionStatus = Self.keyword("ExecutionStatus")
    public static let runID = Self.keyword("RunId")
    public static let taskQueue = Self.keyword("TaskQueue")
    public static let temporalScheduledByID = Self.keyword("TemporalScheduledById")
    public static let workflowID = Self.keyword("WorkflowId")
    public static let workflowType = Self.keyword("WorkflowType")
}

extension SearchAttributeKey where Value == Date {
    /// Creates a key for a ``SearchAttributeType/dateTime`` typed search attribute.
    /// - Parameter name: The name of the attribute. Must be unique across all attributes.
    public static func date(_ name: String) -> Self { .init(name: name, type: .dateTime) }

    public static let closeTime = Self.date("CloseTime")
    public static let executionTime = Self.date("ExecutionTime")
    public static let startTime = Self.date("StartTime")
    public static let temporalScheduledStartTime = Self.date("TemporalScheduledStartTime")
}

extension SearchAttributeKey where Value == Double {
    /// Creates a key for a ``SearchAttributeType/double`` typed search attribute.
    /// - Parameter name: The name of the attribute. Must be unique across all attributes.
    public static func double(_ name: String) -> Self { .init(name: name, type: .double) }
}

extension SearchAttributeKey where Value == Int {
    /// Creates a key for a ``SearchAttributeType/int`` typed search attribute.
    /// - Parameter name: The name of the attribute. Must be unique across all attributes.
    public static func int(_ name: String) -> Self { .init(name: name, type: .int) }

    public static let executionDuration = Self.int("ExecutionDuration")
    public static let historyLength = Self.int("HistoryLength")
    public static let historySizeBytes = Self.int("HistorySizeBytes")
    public static let stateTransitionCount = Self.int("StateTransitionCount")
}

extension SearchAttributeKey where Value == [String] {
    /// Creates a key for a ``SearchAttributeType/keywordList`` typed search attribute.
    /// - Parameter name: The name of the attribute. Must be unique across all attributes.
    public static func keywordList(_ name: String) -> Self { .init(name: name, type: .keywordList) }

    public static let binaryChecksums = Self.keywordList("BinaryChecksums")
    public static let buildIDs = Self.keywordList("BuildIds")
    public static let temporalChangeVersion = Self.keywordList("TemporalChangeVersion")
}
