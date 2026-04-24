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

import SwiftProtobuf

/// A data converter encodes data from your application to an ``Api/Common/V1/Payload`` before sending it
/// to the Temporal server.
///
/// When the server sends data back to a worker the data converter decodes it before
/// passing it to your activity/workflow.
public struct DataConverter: Sendable {
    /// The default data converter.
    ///
    /// This follows the encoding/decoding logic described here
    /// https://docs.temporal.io/dataconversion#default-data-converter.
    public static let `default` = DataConverter(
        payloadConverter: DefaultPayloadConverter(),
        failureConverter: DefaultFailureConverter()
    )

    // TODO: We should check if we should and can make this type generic for performance
    /// The payload converter.
    public let payloadConverter: any PayloadConverter
    /// The failure converter.
    public let failureConverter: any FailureConverter
    /// The payload codec.
    public let payloadCodec: (any PayloadCodec)?

    /// Creates a new data converter.
    ///
    /// - Parameters:
    ///   - payloadConverter: The payload converter.
    ///   - failureConverter: The failure converter.
    ///   - payloadCodec: The payload codec. Defaults to `nil`.
    public init(
        payloadConverter: any PayloadConverter,
        failureConverter: any FailureConverter,
        payloadCodec: (any PayloadCodec)? = nil
    ) {
        self.payloadConverter = payloadConverter
        self.failureConverter = failureConverter
        self.payloadCodec = payloadCodec
    }

    /// Converts a variadic list of optional values into an array of payloads.
    ///
    /// Each value is individually converted using the payload converter and optionally
    /// encoded through the payload codec if one is configured.
    ///
    /// - Parameter values: A variadic list of optional values to convert.
    /// - Returns: An array of payloads, one per input value.
    /// - Throws: If any value cannot be converted by the payload converter or encoded by the payload codec.
    public func convertValues<each Value>(
        _ values: repeat (each Value)?
    ) async throws -> [Api.Common.V1.Payload] {
        var payloads = [Api.Common.V1.Payload]()
        for value in repeat each values {
            try await payloads.append(self.convertValue(value))
        }
        return payloads
    }

    /// Converts a single optional value into a payload.
    ///
    /// If the value is `Void`, an empty payload is returned. Otherwise, the value is converted
    /// using the payload converter and optionally encoded through the payload codec.
    ///
    /// - Parameter value: The value to convert.
    /// - Returns: The converted payload.
    /// - Throws: If the value cannot be converted by the payload converter or encoded by the payload codec.
    public func convertValue<Value>(
        _ value: Value?
    ) async throws -> Api.Common.V1.Payload {
        if value is Void {
            return .init()
        }

        let payload = try self.payloadConverter.convertValue(value)

        // If a payload codec is configured we have to encode it now.
        if let payloadCodec {
            return try await payloadCodec.encode(payload: payload)
        }

        return payload
    }

    /// Converts an array of payloads into a tuple of typed values.
    ///
    /// The number of payloads must match the number of requested value types. Each payload is
    /// individually decoded, optionally through the payload codec first, and then through the
    /// payload converter.
    ///
    /// - Parameters:
    ///   - payloads: The array of payloads to convert.
    ///   - valueTypes: The expected types to decode each payload into.
    /// - Returns: A tuple of decoded values matching the requested types.
    /// - Throws: If the number of payloads does not match the number of types, or if any payload
    ///   cannot be decoded.
    public func convertPayloads<each Value>(
        _ payloads: [Api.Common.V1.Payload],
        as valueTypes: repeat (each Value).Type
    ) async throws -> (repeat each Value) {
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

        return try await (repeat self.convertPayload(payloads.removeFirst()) as each Value)
    }

    /// Converts a single payload into a typed value.
    ///
    /// If the requested type is `Void`, the payload is ignored and `Void` is returned.
    /// Otherwise, the payload is optionally decoded through the payload codec first,
    /// and then converted using the payload converter.
    ///
    /// - Parameters:
    ///   - payload: The payload to convert.
    ///   - valueType: The expected type to decode the payload into.
    /// - Returns: The decoded value.
    /// - Throws: If the payload cannot be decoded by the payload codec or converted by the
    ///   payload converter.
    public func convertPayload<Value>(
        _ payload: Api.Common.V1.Payload,
        as valueType: Value.Type = Value.self
    ) async throws -> Value {
        if Value.self == Void.self {
            return () as! Value
        }
        var payload = payload

        // If a payload codec is configured we have to decode the payload first.
        if let payloadCodec {
            payload = try await payloadCodec.decode(payload: payload)
        }

        return try self.payloadConverter.convertPayload(payload, as: Value.self)
    }

    /// Converts a Swift error into a Temporal failure proto.
    ///
    /// The error is first converted using the failure converter, and then optionally encoded
    /// through the payload codec. If codec encoding fails, a generic failure with the message
    /// "Failed to encode failure" is returned.
    ///
    /// - Parameter error: The error to convert.
    /// - Returns: The converted Temporal failure proto.
    public func convertError(_ error: any Error) async -> Api.Failure.V1.Failure {
        let temporalFailure = self.failureConverter.convertError(
            error,
            payloadConverter: self.payloadConverter
        )

        // If a payload codec is configured we have to encode it now.
        if let payloadCodec {
            do {
                return try await payloadCodec.encode(failure: temporalFailure)
            } catch {
                return Api.Failure.V1.Failure.with {
                    $0.message = "Failed to encode failure"
                    $0.source = "swift-temporal-sdk"
                }
            }
        }

        return temporalFailure
    }

    /// Converts a Temporal failure proto back into a Swift error.
    ///
    /// The failure is optionally decoded through the payload codec first, and then converted
    /// using the failure converter. If codec decoding fails, a ``BasicTemporalFailureError``
    /// with the message "Failed to decode failure" is returned.
    ///
    /// - Parameter temporalFailure: The Temporal failure proto to convert.
    /// - Returns: The converted Swift error.
    public func convertFailure(
        _ temporalFailure: Api.Failure.V1.Failure
    ) async -> any Error {
        var temporalFailure = temporalFailure

        // If a payload codec is configured we have to decode the payload first.
        if let payloadCodec {
            do {
                temporalFailure = try await payloadCodec.decode(failure: temporalFailure)
            } catch {
                return BasicTemporalFailureError(
                    message: "Failed to decode failure",
                    stackTrace: ""
                )
            }
        }

        let error = self.failureConverter.convertFailure(
            temporalFailure,
            payloadConverter: self.payloadConverter
        )

        return error
    }
}
