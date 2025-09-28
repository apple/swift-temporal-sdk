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

/// A payload converter transforms between Swift types and ``TemporalPayload``.
///
/// - Important: Payload converters **must be** deterministic since they are called from within a workflow.
public protocol PayloadConverter: Sendable {
    /// Converts the given value to a ``TemporalPayload``.
    ///
    /// If a converter can't convert a type it is expected to throw an error.
    ///
    /// - Note: The value type is optional to allow converters to detect optional values.
    ///
    /// - Parameter value: The value to convert.
    /// - Returns: The converted payload.
    func convertValue(_ value: some Any) throws -> TemporalPayload

    /// Converts the given payload to a Swift type.
    ///
    /// - Parameters:
    ///   - payload: The payload to convert.
    ///   - valueType: The expected return type.
    /// - Returns: The converted type.
    func convertPayload<Value>(
        _ payload: TemporalPayload,
        as valueType: Value.Type
    ) throws -> Value
}

extension PayloadConverter {
    package func convertValues<each Value>(
        _ values: repeat (each Value)
    ) throws -> [TemporalPayload] {
        var payloads = [TemporalPayload]()
        for value in repeat each values {
            try payloads.append(self.convertValueHandlingVoid(value))
        }
        return payloads
    }

    package func convertValueHandlingVoid<Value>(
        _ value: Value
    ) throws -> TemporalPayload {
        if Value.self == Void.self {
            return .init(data: .init(), metadata: [:])
        }

        return try self.convertValue(value)
    }

    package func convertPayloads<each Value>(
        _ payloads: [TemporalPayload],
        as valueTypes: repeat (each Value).Type
    ) throws -> (repeat each Value) {

        var payloads = payloads

        // This is just a silly hack to get the number of elements in a parameter pack
        var requestedCount = 0
        // swift-format-ignore: NoAssignmentInExpressions
        _ = (repeat (nil as (each Value)?, requestedCount += 1))

        guard requestedCount == payloads.count else {
            throw ArgumentError(
                message: "Mismatched number of values and payloads"
            )
        }

        return try (repeat self.convertPayloadHandlingVoid(payloads.removeFirst(), as: (each Value).self) as each Value)
    }

    package func convertPayloadHandlingVoid<Value>(
        _ payload: TemporalPayload,
        as valueType: Value.Type = Value.self
    ) throws -> Value {
        if Value.self == Void.self {
            return () as! Value
        }

        return try self.convertPayload(payload, as: valueType)
    }
}
