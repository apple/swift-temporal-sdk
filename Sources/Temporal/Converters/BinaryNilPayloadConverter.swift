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

/// A payload converter that handles `nil` (`Optional<T>.none`) values.
public struct BinaryNilPayloadConverter: EncodingPayloadConverter {
    public static let encoding = Encodings.binaryNil

    /// Creates a new binary nil payload converter.
    public init() {}

    public func convertValue(_ value: some Any) throws -> Api.Common.V1.Payload {
        guard let optionalValue = value as? any OptionalValue, optionalValue.isNil else {
            throw PayloadConverterError.encodingFailed(
                converter: "BinaryNilPayloadConverter",
                reason: "value of type '\(type(of: value))' is not a nil optional"
            )
        }

        return createPayload(for: [])
    }

    public func convertPayload<Value>(
        _ payload: Api.Common.V1.Payload,
        as valueType: Value.Type
    ) throws -> Value {
        guard payload.data.isEmpty else {
            throw PayloadConverterError.decodingFailed(
                converter: "BinaryNilPayloadConverter",
                reason: "cannot decode a non-empty payload (\(payload.data.count) bytes) as a nil value"
            )
        }

        guard let optional = valueType as? any OptionalValue.Type else {
            throw PayloadConverterError.decodingFailed(
                converter: "BinaryNilPayloadConverter",
                reason: "requested type '\(valueType)' is not an optional"
            )
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
