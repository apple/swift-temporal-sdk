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
    private struct EncodingError: Error {}
    private struct DecodingError: Error {}

    public static let encoding = Encodings.binaryProtobuf

    public init() {}

    public func convertValue(_ value: some Any) throws -> Api.Common.V1.Payload {
        guard let value = value as? any Message else {
            throw EncodingError()
        }

        return createPayload(for: (try value.serializedBytes() as [UInt8]))
    }

    public func convertPayload<Value>(
        _ payload: Api.Common.V1.Payload,
        as valueType: Value.Type
    ) throws -> Value {
        guard let messageType = Value.self as? any Message.Type else {
            throw DecodingError()
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
