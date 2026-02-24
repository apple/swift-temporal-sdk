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

import struct Foundation.Data

/// A binary payload converter can convert `Array<UInt8>` and `Data` values.
public struct BinaryPayloadConverter: EncodingPayloadConverter {
    private struct EncodingError: Error {}
    private struct DecodingError: Error {}

    public static let encoding = Encodings.binaryPlain

    /// Initializes a new binary payload converter.
    public init() {}

    public func convertValue(_ value: some Any) throws -> Api.Common.V1.Payload {
        // We are checking if the value is a Sequence of UInt8 first since
        // otherwise we would wrongly convert empty Array's of other Element types.
        // This is how Swift's dynamic casting for empty works
        // https://github.com/swiftlang/swift/blob/main/docs/DynamicCasting.md#arraysetdictionary-casts
        if let value = value as? any Sequence<UInt8> {
            if let value = value as? [UInt8] {
                return createPayload(for: value)
            } else if let value = value as? Data {
                return createPayload(for: value)
            }
        }

        throw EncodingError()
    }

    public func convertPayload<Value>(
        _ payload: Api.Common.V1.Payload,
        as valueType: Value.Type
    ) throws -> Value {
        // The force unwraps are safe
        if valueType is [UInt8].Type {
            return Array(payload.data) as! Value
        } else if valueType is Data.Type {
            return payload.data as! Value
        }

        throw DecodingError()
    }
}
