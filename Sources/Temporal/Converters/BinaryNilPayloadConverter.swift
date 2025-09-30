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

/// The binary nil payload converter can convert `nil` (`Optional<T>.none`) values.
public struct BinaryNilPayloadConverter: EncodingPayloadConverter {
    private struct EncodingError: Error {}
    private struct DecodingError: Error {}

    public static let encoding = Encodings.binaryNil

    /// Creates a new binary nil payload converter.
    public init() {}

    public func convertValue(_ value: some Any) throws -> TemporalPayload {
        guard let optionalValue = value as? OptionalValue, optionalValue.isNil else {
            throw EncodingError()
        }

        return createPayload(for: [])
    }

    public func convertPayload<Value>(
        _ payload: TemporalPayload,
        as valueType: Value.Type
    ) throws -> Value {
        guard payload.data.isEmpty else {
            throw DecodingError()
        }

        guard let optional = valueType as? OptionalValue.Type else {
            throw DecodingError()
        }

        // This force unwrap is safe
        return optional.nil as! Value
    }
}

/// This protocol and the below extension on Optional allow us to identify
/// optional generic types.
protocol OptionalValue {
    var isNil: Bool { get }
    static var `nil`: Self { get }
}

extension Optional: OptionalValue {
    var isNil: Bool {
        return self == nil
    }

    static var `nil`: Self {
        return nil
    }
}
