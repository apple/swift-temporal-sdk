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
/// to the temporal server.
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

    /// Initializes a new data converter.
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

    package func convertValues<each Value>(
        _ values: repeat (each Value)?
    ) async throws -> [Api.Common.V1.Payload] {
        var payloads = [Api.Common.V1.Payload]()
        for value in repeat each values {
            try await payloads.append(self.convertValue(value))
        }
        return payloads
    }

    package func convertValue<Value>(
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

    package func convertPayloads<each Value>(
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

    package func convertPayload<Value>(
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

    package func convertError(_ error: any Error) async -> Api.Failure.V1.Failure {
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

    package func convertFailure(
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
