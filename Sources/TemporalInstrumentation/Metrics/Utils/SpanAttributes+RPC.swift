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

import Logging
import OTelSemanticConventions
import Tracing

@dynamicMemberLookup
package struct RPCAttributes: SpanAttributeNamespace {
    package struct NestedSpanAttributes: NestedSpanAttributesProtocol {
        package var system: Key<String> {
            "rpc.system"
        }

        package var service: Key<String> {
            "rpc.service"
        }

        package var method: Key<String> {
            "rpc.method"
        }

        package init() {}
    }

    package var attributes: SpanAttributes

    package init(attributes: SpanAttributes) {
        self.attributes = attributes
    }
}

extension RPCAttributes {
    /// Message Event Attributes.
    ///
    /// See https://github.com/open-telemetry/semantic-conventions/blob/v1.27.0/docs/rpc/rpc-spans.md#events
    package struct MessageAttributes: SpanAttributeNamespace {
        package struct NestedSpanAttributes: NestedSpanAttributesProtocol {
            package var type: Key<String> {
                "rpc.message.type"
            }

            package var id: Key<Int> {
                "rpc.message.id"
            }

            package var compressedSizeInBytes: Key<Int> {
                "rpc.message.compressed_size"
            }

            package var uncompressedSizeInBytes: Key<Int> {
                "rpc.message.uncompressed_size"
            }

            package init() {}
        }

        package var attributes: SpanAttributes

        package init(attributes: SpanAttributes) {
            self.attributes = attributes
        }
    }

    package var message: MessageAttributes {
        get {
            MessageAttributes(attributes: self.attributes)
        }
        set {
            self.attributes = newValue.attributes
        }
    }
}

extension RPCAttributes {
    /// `https://opentelemetry.io/docs/specs/semconv/rpc/grpc`.
    package struct GRPCAttributes: SpanAttributeNamespace {
        package struct NestedSpanAttributes: NestedSpanAttributesProtocol {
            /// The [numeric status code](https://github.com/grpc/grpc/blob/v1.33.2/doc/statuscodes.md) of the gRPC request.
            ///
            /// E.g. ``RPCAttributes/GRPCAttributes/StatusCode/ok``.
            package var statusCode: Key<String> {
                "rpc.grpc.status_code"
            }

            package static var requestMetadata: Key<String> {
                "rpc.grpc.request.metdata"
            }

            package static var responseMetadata: Key<String> {
                "rpc.grpc.response.metdata"
            }

            package init() {}
        }

        package var attributes: SpanAttributes

        package init(attributes: SpanAttributes) {
            self.attributes = attributes
        }
    }

    package var gRPC: GRPCAttributes {
        get {
            GRPCAttributes(attributes: self.attributes)
        }
        set {
            self.attributes = newValue.attributes
        }
    }
}

extension RPCAttributes.GRPCAttributes {
    package struct RequestAttributes: SpanAttributeNamespace {
        package struct NestedSpanAttributes: NestedSpanAttributesProtocol {
            package init() {}
        }

        package var attributes: SpanAttributes

        package init(attributes: SpanAttributes) {
            self.attributes = attributes
        }
    }

    package struct ResponseAttributes: SpanAttributeNamespace {
        package struct NestedSpanAttributes: NestedSpanAttributesProtocol {
            package init() {}
        }

        package var attributes: SpanAttributes

        package init(attributes: SpanAttributes) {
            self.attributes = attributes
        }
    }

    package var request: RequestAttributes {
        get {
            RequestAttributes(attributes: self.attributes)
        }
        set {
            self.attributes = newValue.attributes
        }
    }

    package var response: ResponseAttributes {
        get {
            ResponseAttributes(attributes: self.attributes)
        }
        set {
            self.attributes = newValue.attributes
        }
    }
}

extension RPCAttributes.GRPCAttributes.RequestAttributes {
    package struct MetadataAttributes: SpanAttributeNamespace {
        package struct NestedSpanAttributes: NestedSpanAttributesProtocol {
            package init() {}
        }

        package var attributes: SpanAttributes

        package init(attributes: SpanAttributes) {
            self.attributes = attributes
        }
    }

    package var metadata: MetadataAttributes {
        get {
            MetadataAttributes(attributes: self.attributes)
        }
        set {
            self.attributes = newValue.attributes
        }
    }
}

extension RPCAttributes.GRPCAttributes.ResponseAttributes {
    package struct MetadataAttributes: SpanAttributeNamespace {
        package struct NestedSpanAttributes: NestedSpanAttributesProtocol {
            package init() {}
        }

        package var attributes: SpanAttributes

        package init(attributes: SpanAttributes) {
            self.attributes = attributes
        }
    }

    package var metadata: MetadataAttributes {
        get {
            MetadataAttributes(attributes: self.attributes)
        }
        set {
            self.attributes = newValue.attributes
        }
    }
}

extension SpanAttributes {
    package var rpc: RPCAttributes {
        get {
            RPCAttributes(attributes: self)
        }
        set {
            self = newValue.attributes
        }
    }
}

extension RPCAttributes.MessageAttributes.NestedSpanAttributes {
    /// Flag to indicate if the message is compressed.
    package var compressed: Key<Bool> {
        "rpc.message.compressed"
    }
}

extension RPCAttributes.GRPCAttributes.RequestAttributes.NestedSpanAttributes {
    package var streaming: Key<Bool> {
        "rpc.grpc.request.streaming"
    }
}

extension RPCAttributes.GRPCAttributes.ResponseAttributes.NestedSpanAttributes {
    package var streaming: Key<Bool> {
        "rpc.grpc.response.streaming"
    }
}
