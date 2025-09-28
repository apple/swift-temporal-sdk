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

import ServiceContextModule
import Tracing

/// Injects the service context into the Temporal headers.
package struct TemporalHeaderInjector: Injector {
    package typealias Carrier = [String: String]

    package func inject(_ value: String, forKey key: String, into carrier: inout Carrier) {
        carrier[key] = value
    }
}

/// Extracts the service context from the Temporal headers.
package struct TemporalHeaderExtractor: Extractor {
    package typealias Carrier = [String: String]

    package func extract(key: String, from carrier: Carrier) -> String? {
        carrier[key]
    }
}
