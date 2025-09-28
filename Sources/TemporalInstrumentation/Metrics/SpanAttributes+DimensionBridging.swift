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

import Tracing

extension Array where Element == (String, String) {
    package mutating func append<T: SpanAttributeConvertible>(attribute keyPath: WritableKeyPath<SpanAttributes, T?>, _ value: T) {
        var attributes = SpanAttributes()
        attributes[keyPath: keyPath] = value

        // swift-format-ignore: ReplaceForEachWithForLoop
        attributes.forEach { key, attribute in
            append((key, attribute.dimensionDescription))
        }
    }
}

extension SpanAttribute {
    var dimensionDescription: String {
        switch self {
        case let .int32(value):
            value.description
        case let .int64(value):
            value.description
        case let .int32Array(value):
            value.description
        case let .int64Array(value):
            value.description
        case let .double(value):
            value.description
        case let .doubleArray(value):
            value.description
        case let .bool(value):
            value.description
        case let .boolArray(value):
            value.description
        case let .string(value):
            value
        case let .stringArray(value):
            value.description
        case let .stringConvertible(value):
            value.description
        case let .stringConvertibleArray(value):
            value.description
        default:
            "<unknown>"
        }
    }
}
