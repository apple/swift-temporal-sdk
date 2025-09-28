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

/// Server tracing semantics.
///
/// See https://github.com/open-telemetry/semantic-conventions/blob/v1.27.0/docs/attributes-registry/server.md
@dynamicMemberLookup
package struct ServerAttributes: SpanAttributeNamespace {
    package struct NestedSpanAttributes: NestedSpanAttributesProtocol {
        /// Server address.
        ///
        /// Server domain name if available without reverse DNS lookup; otherwise, IP address or Unix domain socket name.
        package var address: Key<String> {
            "server.address"
        }

        /// Server port number.
        package var port: Key<Int> {
            "server.port"
        }

        package init() {}
    }

    package var attributes: SpanAttributes

    package init(attributes: SpanAttributes) {
        self.attributes = attributes
    }
}

extension SpanAttributes {
    package var server: ServerAttributes {
        get {
            ServerAttributes(attributes: self)
        }
        set {
            self = newValue.attributes
        }
    }
}
