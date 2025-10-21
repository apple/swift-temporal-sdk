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

public import struct Foundation.Date

/// A collection of search attribute key-value pairs.
public struct SearchAttributeCollection: Hashable, Sendable {
    typealias Storage = [SearchAttributeKeyStorage: StorageValue]

    enum StorageValue: Hashable, Sendable {
        case unset
        case bool(Bool)
        case date(Date)
        case double(Double)
        case int(Int)
        case string(String)
        case stringArray([String])

        var value: Any? {
            switch self {
            case .unset: nil
            case .bool(let value): value
            case .date(let value): value
            case .double(let value): value
            case .int(let value): value
            case .string(let value): value
            case .stringArray(let value): value
            }
        }

        var boolValue: Bool? {
            if case .bool(let value) = self { value } else { nil }
        }
        var dateValue: Date? {
            if case .date(let value) = self { value } else { nil }
        }
        var doubleValue: Double? {
            if case .double(let value) = self { value } else { nil }
        }
        var intValue: Int? {
            if case .int(let value) = self { value } else { nil }
        }
        var stringValue: String? {
            if case .string(let value) = self { value } else { nil }
        }
        var stringArrayValue: [String]? {
            if case .stringArray(let value) = self { value } else { nil }
        }
    }

    public struct Index: Comparable, Sendable {
        let rawIndex: Storage.Index

        init(_ rawIndex: Storage.Index) {
            self.rawIndex = rawIndex
        }

        public static func < (lhs: Self, rhs: Self) -> Bool {
            lhs.rawIndex < rhs.rawIndex
        }
    }

    var storage: Storage = [:]

    /// Creates an empty ``SearchAttributeCollection``.
    public init() {}

    /// A convenience to create an ``SearchAttributeCollection`` instance using the given builder closure.
    /// - Parameter builder: The closure to use when creating the instance.
    public init(_ builder: (inout SearchAttributeCollection) throws -> Void) rethrows {
        var instance = SearchAttributeCollection()
        try builder(&instance)
        self = consume instance
    }
}

extension SearchAttributeCollection: CustomDebugStringConvertible {
    public var debugDescription: String {
        "["
            + map { key, value in
                "\(key.name)(\(key.type.indexedValueTypeString)): \(value.flatMap { .init(describing: $0) } ?? "<unset>" )"
            }.joined(separator: ", ") + "]"
    }
}

extension SearchAttributeCollection {
    public subscript(_ key: SearchAttributeKey<Bool>) -> Bool? {
        get { storage[key.storage]?.boolValue }
        set { storage[key.storage] = newValue.flatMap { .bool($0) } ?? .unset }
    }
    public subscript(_ key: SearchAttributeKey<Date>) -> Date? {
        get { storage[key.storage]?.dateValue }
        set { storage[key.storage] = newValue.flatMap { .date($0) } ?? .unset }
    }
    public subscript(_ key: SearchAttributeKey<Double>) -> Double? {
        get { storage[key.storage]?.doubleValue }
        set { storage[key.storage] = newValue.flatMap { .double($0) } ?? .unset }
    }
    public subscript(_ key: SearchAttributeKey<Int>) -> Int? {
        get { storage[key.storage]?.intValue }
        set { storage[key.storage] = newValue.flatMap { .int($0) } ?? .unset }
    }
    public subscript(_ key: SearchAttributeKey<String>) -> String? {
        get { storage[key.storage]?.stringValue }
        set { storage[key.storage] = newValue.flatMap { .string($0) } ?? .unset }
    }
    public subscript(_ key: SearchAttributeKey<[String]>) -> [String]? {
        get { storage[key.storage]?.stringArrayValue }
        set { storage[key.storage] = newValue.flatMap { .stringArray($0) } ?? .unset }
    }
}

extension SearchAttributeCollection: Collection {
    /// The number of key-value pairs in the collection.
    ///
    /// - Complexity: O(1).
    public var count: Int { storage.count }

    /// A Boolean value that indicates whether the collection is empty.
    public var isEmpty: Bool { storage.isEmpty }

    public var startIndex: Index { .init(storage.startIndex) }

    public var endIndex: Index { .init(storage.endIndex) }

    public func index(after i: Index) -> Index { .init(storage.index(after: i.rawIndex)) }

    public subscript(index: Index) -> (AnySearchAttributeKey, Any?) {
        (AnySearchAttributeKey(storage.keys[index.rawIndex]), storage[index.rawIndex].value.value)
    }

    /// Returns and removes the boolean value for the specified key from the collection.
    /// - Parameter key: The key of the value to remove.
    @discardableResult
    public mutating func removeValue(forKey key: SearchAttributeKey<Bool>) -> Bool? {
        removeValue(forKey: key.storage)?.boolValue
    }

    /// Returns and removes the date value for the specified key from the collection.
    /// - Parameter key: The key of the value to remove.
    @discardableResult
    public mutating func removeValue(forKey key: SearchAttributeKey<Date>) -> Date? {
        removeValue(forKey: key.storage)?.dateValue
    }

    /// Returns and removes the double value for the specified key from the collection.
    /// - Parameter key: The key of the value to remove.
    @discardableResult
    public mutating func removeValue(forKey key: SearchAttributeKey<Double>) -> Double? {
        removeValue(forKey: key.storage)?.doubleValue
    }

    /// Returns and removes the integer value for the specified key from the collection.
    /// - Parameter key: The key of the value to remove.
    @discardableResult
    public mutating func removeValue(forKey key: SearchAttributeKey<Int>) -> Int? {
        removeValue(forKey: key.storage)?.intValue
    }

    /// Returns and removes the string value for the specified key from the collection.
    /// - Parameter key: The key of the value to remove.
    @discardableResult
    public mutating func removeValue(forKey key: SearchAttributeKey<String>) -> String? {
        removeValue(forKey: key.storage)?.stringValue
    }

    /// Returns and removes the string array value for the specified key from the collection.
    /// - Parameter key: The key of the value to remove.
    @discardableResult
    public mutating func removeValue(forKey key: SearchAttributeKey<[String]>) -> [String]? {
        removeValue(forKey: key.storage)?.stringArrayValue
    }

    /// Returns a new collection containing, the elements of the sequence that satisfy the given predicate.
    /// - Parameter isIncluded: The predicate to test each key-value pair of the collection.
    package func filter(_ isIncluded: ((key: AnySearchAttributeKey, value: Any?)) throws -> Bool) rethrows -> Self {
        try Self { new in
            for (key, value) in storage {
                guard try isIncluded((.init(key), value.value)) else { continue }
                new.storage[key] = value
            }
        }
    }

    subscript(_ key: AnySearchAttributeKey) -> StorageValue? {
        get { storage[key.storage] }
        set { storage[key.storage] = newValue }
    }

    /// Returns and removes the value for the specified key from the collection.
    /// - Parameter key: The key of the value to remove.
    @discardableResult
    mutating func removeValue(forKey key: SearchAttributeKeyStorage) -> StorageValue? {
        storage.removeValue(forKey: key)
    }

    /// Returns and removes the value for the specified key from the collection.
    /// - Parameter key: The key of the value to remove.
    @discardableResult
    mutating func removeValue(forKey key: AnySearchAttributeKey) -> StorageValue? {
        removeValue(forKey: key.storage)
    }

    /// Merges the key-value pairs in the given sequence into the collection,
    /// using a combining closure to determine the value for any duplicate keys.
    mutating func merge(_ other: Self, uniquingKeysWith combine: (StorageValue, StorageValue) throws -> StorageValue) rethrows {
        for (key, otherValue) in other.storage {
            if let selfValue = storage[key] {
                storage[key] = try combine(selfValue, otherValue)
            } else {
                storage[key] = otherValue
            }
        }
    }

    /// Creates a new collection by merging the passed in key-value pair collection into self, using a combining
    /// closure to determine the value for duplicate keys.
    func merging(_ other: Self, uniquingKeysWith combine: (StorageValue, StorageValue) throws -> StorageValue) rethrows -> Self {
        var copy = self
        try copy.merge(other, uniquingKeysWith: combine)
        return copy
    }

    /// Merges self with the passes in collection, inserting and updating as needed and removing key-value
    /// pairs that are marked as unset.
    /// - Parameter other: The collection of key-value pair updates to be performed.
    mutating func upsert(with other: Self) {
        for (key, value) in other.storage {
            guard value != .unset else {
                removeValue(forKey: key)
                continue
            }
            storage[key] = value
        }
    }
}
