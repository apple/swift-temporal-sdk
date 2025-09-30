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

import Logging
import Tracing

extension Logger.Metadata {
    package mutating func append<T: SpanAttributeConvertible>(attribute keyPath: WritableKeyPath<SpanAttributes, T?>, _ value: T) {
        var attributes = SpanAttributes()
        attributes[keyPath: keyPath] = value

        // swift-format-ignore: ReplaceForEachWithForLoop
        attributes.forEach { key, attribute in
            self[key] = .string(attribute.dimensionDescription)
        }
    }
}
