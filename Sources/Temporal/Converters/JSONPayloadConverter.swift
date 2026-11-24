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

#if canImport(FoundationEssentials)
public import struct FoundationEssentials.Data
public import struct FoundationEssentials.Date
public import class FoundationEssentials.JSONDecoder
public import class FoundationEssentials.JSONEncoder
#else
public import struct Foundation.Data
public import struct Foundation.Date
public import class Foundation.JSONDecoder
public import class Foundation.JSONEncoder
#endif

/// A payload converter for types conforming to `Encodable` and `Decodable` using JSON encoding.
public struct JSONPayloadConverter: EncodingPayloadConverter {
    public static let encoding = Encodings.jsonPlain

    private let jsonEncoder: JSONEncoder
    private let jsonDecoder: JSONDecoder

    /// ISO 8601 with fractional seconds, e.g. `2025-01-19T16:00:00.250Z`.
    private static let dateStyleWithFractionalSeconds = Date.ISO8601FormatStyle(includingFractionalSeconds: true)

    /// ISO 8601 without fractional seconds, e.g. `2025-01-19T16:00:00Z`.
    private static let dateStyleWithoutFractionalSeconds = Date.ISO8601FormatStyle()

    /// The default JSONEncoder used by the JSONPayloadConverter.
    ///
    /// Dates are written as ISO 8601 strings with millisecond precision, e.g.
    /// `2025-01-19T16:00:00.250Z`, so that sub-second timestamps are not truncated to the second.
    public static let defaultJSONEncoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .custom { date, encoder in
            var container = encoder.singleValueContainer()
            try container.encode(dateStyleWithFractionalSeconds.format(date))
        }
        return encoder
    }()

    /// The default JSONDecoder used by the JSONPayloadConverter.
    ///
    /// Dates are read as ISO 8601 strings with or without fractional seconds, so payloads written
    /// by earlier versions of this SDK and by other Temporal SDKs keep decoding.
    public static let defaultJSONDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let string = try container.decode(String.self)
            if let date = try? dateStyleWithFractionalSeconds.parse(string) { return date }
            if let date = try? dateStyleWithoutFractionalSeconds.parse(string) { return date }
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Expected date string to be ISO8601-formatted."
            )
        }
        return decoder
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

    public func convertValue(_ value: some Any) throws -> Api.Common.V1.Payload {
        guard let encodable = value as? any Encodable else {
            throw PayloadConverterError.encodingFailed(
                converter: "JSONPayloadConverter",
                reason: "value of type '\(type(of: value))' does not conform to 'Encodable'"
            )
        }

        let encodedValue = try self.jsonEncoder.encode(encodable)

        return createPayload(for: encodedValue)
    }

    public func convertPayload<Value>(
        _ payload: Api.Common.V1.Payload,
        as valueType: Value.Type
    ) throws -> Value {
        guard let decodableType = Value.self as? any Decodable.Type else {
            throw PayloadConverterError.decodingFailed(
                converter: "JSONPayloadConverter",
                reason: "requested type '\(valueType)' does not conform to 'Decodable'"
            )
        }

        let decoded = try self.jsonDecoder.decode(decodableType, from: payload.data)
        // This force unwrap is safe
        return decoded as! Value
    }

}
