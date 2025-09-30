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

/// A payload converter that uses multiple implementations to perform payload
/// conversions.
///
/// When encoding a value, each converter is tried in sequence until one of
/// them is able to convert the value to a ``TemporalPayload``.
///
/// When decoding the encoding of the payload is examined and the first
/// underlying converter that reports processing that encoding is used for
/// decoding the payload.
public struct CompositePayloadConverter<each Converter: EncodingPayloadConverter>: PayloadConverter {
    private struct EncodingError: Error {}
    private struct DecodingError: Error {}

    private let converter: (repeat each Converter)

    public init(_ converter: repeat each Converter) {
        self.converter = (repeat each converter)
    }

    public func convertValue(_ value: some Any) throws -> TemporalPayload {
        if let value = value as? TemporalRawValue {
            return value.payload
        }

        for converter in repeat (each converter) {
            if let result = try? converter.convertValue(value) {
                return result
            }
        }

        throw EncodingError()
    }

    public func convertPayload<Value>(
        _ payload: TemporalPayload,
        as valueType: Value.Type
    ) throws -> Value {
        if Value.self == TemporalRawValue.self {
            return TemporalRawValue(payload) as! Value
        }

        guard let encoding = payload.metadata[Encodings.encodingKey] else {
            throw DecodingError()
        }

        for (type, converter) in repeat ((each Converter).self, each converter) {
            if Array(type.encoding.utf8) == encoding {
                return try converter.convertPayload(payload, as: valueType)
            }
        }

        throw DecodingError()
    }
}
