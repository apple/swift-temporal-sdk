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

/// A key (unique name and type) used to specify a search attribute.
///
/// Use one of the static functions (``bool(_:)``, ``date(_:)``, ``double(_:)``, and others) to create
/// a new key.
public struct SearchAttributeKey<Value: Sendable>: Hashable, Sendable {
    let storage: SearchAttributeKeyStorage

    init(name: String, type: Api.Enums.V1.IndexedValueType) {
        self.init(storage: .init(name: name, type: type))
    }

    init(storage: SearchAttributeKeyStorage) {
        self.storage = storage
    }

    /// The name of the attribute.
    public var name: String { storage.name }

    /// The type of the attribute.
    public var type: Api.Enums.V1.IndexedValueType { storage.type }
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

    /// Creates a type-erased search attribute key from a typed key.
    public init<Value>(_ key: SearchAttributeKey<Value>) {
        self.storage = key.storage
    }

    /// The name of the attribute.
    public var name: String { storage.name }

    /// The type of the attribute.
    public var type: Api.Enums.V1.IndexedValueType { storage.type }
}
extension AnySearchAttributeKey: CustomStringConvertible {
    public var description: String { name }
}

struct SearchAttributeKeyStorage: Hashable, Sendable {
    let name: String
    let type: Api.Enums.V1.IndexedValueType
}

// MARK: Define Search Attributes

extension SearchAttributeKey where Value == Bool {
    /// Creates a key for a ``Api/Enums/V1/IndexedValueType/bool`` typed search attribute.
    /// - Parameter name: The name of the attribute. Must be unique across all attributes.
    public static func bool(_ name: String) -> Self { .init(name: name, type: .bool) }

    /// A Boolean value that indicates whether a Temporal schedule is paused.
    public static let temporalSchedulePaused = Self.bool("TemporalSchedulePaused")
}

extension SearchAttributeKey where Value == String {
    /// Creates a key for a ``Api/Enums/V1/IndexedValueType/keyword`` typed search attribute.
    /// - Parameter name: The name of the attribute. Must be unique across all attributes.
    public static func keyword(_ name: String) -> Self { .init(name: name, type: .keyword) }

    /// Creates a key for a ``Api/Enums/V1/IndexedValueType/text`` typed search attribute.
    /// - Parameter name: The name of the attribute. Must be unique across all attributes.
    public static func text(_ name: String) -> Self { .init(name: name, type: .text) }

    /// The user who initiated a batch operation.
    public static let batcherUser = Self.keyword("BatcherUser")
    /// The current execution status of the workflow.
    public static let executionStatus = Self.keyword("ExecutionStatus")
    /// The run ID of the workflow execution.
    public static let runID = Self.keyword("RunId")
    /// The task queue the workflow is assigned to.
    public static let taskQueue = Self.keyword("TaskQueue")
    /// The ID of the schedule that started this workflow.
    public static let temporalScheduledByID = Self.keyword("TemporalScheduledById")
    /// The unique workflow ID.
    public static let workflowID = Self.keyword("WorkflowId")
    /// The workflow type name.
    public static let workflowType = Self.keyword("WorkflowType")
}

extension SearchAttributeKey where Value == Date {
    /// Creates a key for a ``Api/Enums/V1/IndexedValueType/datetime`` typed search attribute.
    /// - Parameter name: The name of the attribute. Must be unique across all attributes.
    public static func date(_ name: String) -> Self { .init(name: name, type: .datetime) }

    /// The time at which the workflow execution closed.
    public static let closeTime = Self.date("CloseTime")
    /// The time at which the workflow started executing.
    public static let executionTime = Self.date("ExecutionTime")
    /// The time at which the workflow execution was created.
    public static let startTime = Self.date("StartTime")
    /// The scheduled start time for a workflow triggered by a Temporal schedule.
    public static let temporalScheduledStartTime = Self.date("TemporalScheduledStartTime")
}

extension SearchAttributeKey where Value == Double {
    /// Creates a key for a ``Api/Enums/V1/IndexedValueType/double`` typed search attribute.
    /// - Parameter name: The name of the attribute. Must be unique across all attributes.
    public static func double(_ name: String) -> Self { .init(name: name, type: .double) }
}

extension SearchAttributeKey where Value == Int {
    /// Creates a key for a ``Api/Enums/V1/IndexedValueType/int`` typed search attribute.
    /// - Parameter name: The name of the attribute. Must be unique across all attributes.
    public static func int(_ name: String) -> Self { .init(name: name, type: .int) }

    /// The total execution duration of the workflow in nanoseconds.
    public static let executionDuration = Self.int("ExecutionDuration")
    /// The number of events in the workflow history.
    public static let historyLength = Self.int("HistoryLength")
    /// The size of the workflow history in bytes.
    public static let historySizeBytes = Self.int("HistorySizeBytes")
    /// The number of state transitions in the workflow.
    public static let stateTransitionCount = Self.int("StateTransitionCount")
}

extension SearchAttributeKey where Value == [String] {
    /// Creates a key for a ``Api/Enums/V1/IndexedValueType/keywordList`` typed search attribute.
    /// - Parameter name: The name of the attribute. Must be unique across all attributes.
    public static func keywordList(_ name: String) -> Self { .init(name: name, type: .keywordList) }

    /// The binary checksums of workers that have processed the workflow.
    public static let binaryChecksums = Self.keywordList("BinaryChecksums")
    /// The build IDs of workers that have processed the workflow.
    public static let buildIDs = Self.keywordList("BuildIds")
    /// The change versions applied to the workflow via patching.
    public static let temporalChangeVersion = Self.keywordList("TemporalChangeVersion")
}
