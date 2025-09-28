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

/// The default payload converter tries to convert a value using multiple different converters.
///
/// When converting values to payloads the following converters are tried in this order:
/// - ``BinaryNilPayloadConverter``
/// - ``BinaryPayloadConverter``
/// - ``JSONProtobufPayloadConverter``
/// - ``JSONPayloadConverter``
///
/// When converting payloads to values the converter retrives the `encoding` value
/// of the payloads ``TemporalPayload/metadata``.
/// Then it tries to convert the payload using the matching payload converter.
public struct DefaultPayloadConverter: PayloadConverter {
    private struct EncodingError: Error {}
    private struct DecodingError: Error {}

    private let converter = CompositePayloadConverter(
        BinaryNilPayloadConverter(),
        BinaryPayloadConverter(),
        JSONProtobufPayloadConverter(),
        // In practice this payload converter will never be used when encoding a payload as the JSON variant will always accept the objects first.
        // However we keep it around to decode payloads that are encoded using the binary protobuf format.
        BinaryProtobufPayloadConverter(),
        JSONPayloadConverter()
    )

    /// Initializes a new default payload converter.
    public init() {}

    public func convertValue(_ value: some Any) throws -> TemporalPayload {
        return try converter.convertValue(value)
    }

    public func convertPayload<Value>(
        _ payload: TemporalPayload,
        as valueType: Value.Type
    ) throws -> Value {
        return try converter.convertPayload(payload, as: valueType)
    }
}
