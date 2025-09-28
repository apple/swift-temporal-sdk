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

public import struct Foundation.Data
public import class Foundation.JSONDecoder
public import class Foundation.JSONEncoder

/// The JSON payload converter can convert any type conforming to `Encodable`/`Decodable`.
public struct JSONPayloadConverter: EncodingPayloadConverter {
    private struct EncodingError: Error {}
    private struct DecodingError: Error {}

    public static let encoding = Encodings.jsonPlain

    private let jsonEncoder: JSONEncoder
    private let jsonDecoder: JSONDecoder

    /// The default JSONEncoder used by the JSONPayloadConverter.
    public static let defaultJSONEncoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()

    /// The default JSONDecoder used by the JSONPayloadConverter.
    public static let defaultJSONDecoder: JSONDecoder = {
        let encoder = JSONDecoder()
        encoder.dateDecodingStrategy = .iso8601
        return encoder
    }()

    /// Creates a new JSON payload converter.
    ///
    /// - Parameters:
    ///   - jsonEncoder: The JSONEncoder to use. Defaults to a fresh one.
    ///   - jsonDecoder: The JSONDecoder to use. Defaults to a fresh one.
    public init(
        jsonEncoder: JSONEncoder = defaultJSONEncoder,
        jsonDecoder: JSONDecoder = defaultJSONDecoder
    ) {
        self.jsonEncoder = jsonEncoder
        self.jsonDecoder = jsonDecoder
    }

    public func convertValue(_ value: some Any) throws -> TemporalPayload {
        guard let encodable = value as? Encodable else {
            throw EncodingError()
        }

        let encodedValue = try self.jsonEncoder.encode(encodable)

        return createPayload(for: Array(encodedValue))
    }

    public func convertPayload<Value>(
        _ payload: TemporalPayload,
        as valueType: Value.Type
    ) throws -> Value {
        guard let decodableType = Value.self as? Decodable.Type else {
            throw DecodingError()
        }

        let decoded = try self.jsonDecoder.decode(decodableType, from: Data(payload.data))
        // This force unwrap is safe
        return decoded as! Value
    }

}
