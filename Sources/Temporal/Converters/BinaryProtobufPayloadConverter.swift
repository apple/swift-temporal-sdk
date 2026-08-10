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

import Foundation
import SwiftProtobuf

/// Converts any type conforming to `SwiftProtobuf.Message` into binary protobuf encoding.
public struct BinaryProtobufPayloadConverter: EncodingPayloadConverter {
    public static let encoding = Encodings.binaryProtobuf

    /// Creates a new binary protobuf payload converter.
    public init() {}

    public func convertValue(_ value: some Any) throws -> Api.Common.V1.Payload {
        guard let value = value as? any Message else {
            throw PayloadConverterError.encodingFailed(
                converter: "BinaryProtobufPayloadConverter",
                reason: "value of type '\(type(of: value))' does not conform to 'SwiftProtobuf.Message'"
            )
        }

        return createPayload(
            for: (try value.serializedBytes() as [UInt8]),
            additionalMetadata: [
                Encodings.messageTypeKey: Data(type(of: value).protoMessageName.utf8)
            ]
        )
    }

    public func convertPayload<Value>(
        _ payload: Api.Common.V1.Payload,
        as valueType: Value.Type
    ) throws -> Value {
        guard let messageType = Value.self as? any Message.Type else {
            throw PayloadConverterError.decodingFailed(
                converter: "BinaryProtobufPayloadConverter",
                reason: "requested type '\(valueType)' does not conform to 'SwiftProtobuf.Message'"
            )
        }

        let message = try { try self.convertPayload(payload, as: messageType) }()
        // This force unwrap is safe
        return message as! Value
    }

    private func convertPayload<Value: Message>(
        _ payload: Api.Common.V1.Payload,
        as valueType: Value.Type
    ) throws -> Value {
        return try .init(serializedBytes: payload.data)
    }
}
