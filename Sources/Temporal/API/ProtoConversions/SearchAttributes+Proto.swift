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

import struct Foundation.Date

extension Temporal_Api_Common_V1_SearchAttributes {
    init(_ collection: SearchAttributeCollection) {
        for (key, value) in collection {
            // This should be okay to force since the collection can only be created
            // in a type safe way and only handles primitives.
            var payload = try! DataConverter.default.payloadConverter.convertValue(value)
            payload.metadata["type"] = Array(key.type.indexedValueTypeString.utf8)
            indexedFields[key.name] = .init(temporalPayload: payload)
        }
    }
}

extension SearchAttributeCollection {
    init(_ rawSearchAttributes: Temporal_Api_Common_V1_SearchAttributes) throws {
        self = try SearchAttributeCollection.init { builder in
            for (keyName, rawValue) in rawSearchAttributes.indexedFields {
                guard let (value, type) = try StorageValue.convertPayload(rawValue) else { continue }

                // Old servers may have null elements, which we ignore
                guard value.value != nil else { continue }

                let keyStorage = SearchAttributeKeyStorage(name: keyName, type: type)
                builder.storage[keyStorage] = value
            }
        }
    }
}

extension SearchAttributeCollection.StorageValue {
    static func convertPayload(_ payload: Temporal_Api_Common_V1_Payload) throws -> (value: Self, type: SearchAttributeType)? {
        guard let rawType = payload.metadata["type"] else { return nil }
        guard let stringType = String(data: rawType, encoding: .utf8) else { return nil }
        guard let type = SearchAttributeType(indexedValueTypeString: stringType) else { return nil }

        let payload = TemporalPayload(temporalAPIPayload: payload)
        let payloadConverter = DataConverter.default.payloadConverter

        let value: Self =
            switch type {
            case .bool: .bool(try payloadConverter.convertPayload(payload, as: Bool.self))
            case .dateTime: .date(try payloadConverter.convertPayload(payload, as: Date.self))
            case .double: .double(try payloadConverter.convertPayload(payload, as: Double.self))
            case .int: .int(try payloadConverter.convertPayload(payload, as: Int.self))
            case .keyword, .text: .string(try payloadConverter.convertPayload(payload, as: String.self))
            case .keywordList: .stringArray(try payloadConverter.convertPayload(payload, as: [String].self))
            case .unspecified:
                throw TemporalSDKError("Encountered unspecified search attribute type when converting from raw proto.")
            }

        return (value, type)
    }
}
