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

/// A payload converter for `Array<UInt8>` and `Data` values.
public struct BinaryPayloadConverter: EncodingPayloadConverter {
    public static let encoding = Encodings.binaryPlain

    /// Creates a new binary payload converter.
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

        throw PayloadConverterError.encodingFailed(
            converter: "BinaryPayloadConverter",
            reason: "value of type '\(type(of: value))' is not '[UInt8]' or 'Foundation.Data'"
        )
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

        throw PayloadConverterError.decodingFailed(
            converter: "BinaryPayloadConverter",
            reason: "requested type '\(valueType)' is not '[UInt8]' or 'Foundation.Data'"
        )
    }
}
