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

import GRPCCore
import Logging
import OTelSemanticConventions
import Tracing

extension ClientContext {
    func metadata(
        serviceName: String,
        serviceVersion: String?,
        serverHostname: String,
        networkTransportMethod: SpanAttributes.NetworkAttributes.NestedSpanAttributes.TransportEnum,
        requestMetadata: GRPCCore.Metadata
    ) -> Logger.Metadata {
        var metadata: Logger.Metadata = [:]

        // service-level identification
        metadata.append(attribute: \.service.name, serviceName)
        if let serviceVersion {
            metadata.append(attribute: \.service.version, serviceVersion)
        }

        // RPC info
        metadata.append(attribute: \.rpc.system, "grpc")
        metadata.append(attribute: \.rpc.service, self.descriptor.service.fullyQualifiedService)
        metadata.append(attribute: \.rpc.method, self.descriptor.method)

        // Network info
        metadata.append(attribute: \.server.address, serverHostname)
        metadata.append(attribute: \.network.transport, networkTransportMethod)
        switch PeerAddress(self.remotePeer) {
        case let .ipv4(address, port):
            metadata.append(attribute: \.network.type, .ipv4)
            metadata.append(attribute: \.network.peer.address, address)
            if let port {
                metadata.append(attribute: \.network.peer.port, port)
                metadata.append(attribute: \.server.port, port)
            }
        case let .ipv6(address, port):
            metadata.append(attribute: \.network.type, .ipv6)
            metadata.append(attribute: \.network.peer.address, address)
            if let port {
                metadata.append(attribute: \.network.peer.port, port)
                metadata.append(attribute: \.server.port, port)
            }
        case let .unixDomainSocket(path):
            metadata.append(attribute: \.network.peer.address, path)
        case .none:
            break
        }

        switch PeerAddress(self.localPeer) {
        case let .ipv4(address, port):
            metadata.append(attribute: \.network.type, .ipv4)
            metadata.append(attribute: \.network.local.address, address)
            if let port {
                metadata.append(attribute: \.network.local.port, port)
            }
        case let .ipv6(address, port):
            metadata.append(attribute: \.network.type, .ipv6)
            metadata.append(attribute: \.network.local.address, address)
            if let port {
                metadata.append(attribute: \.network.local.port, port)
            }
        case let .unixDomainSocket(path):
            metadata.append(attribute: \.network.local.address, path)
        case .none:
            break
        }

        // Request metadata
        for requestMetadataEntry in requestMetadata {
            metadata[
                RPCAttributes.GRPCAttributes.NestedSpanAttributes.requestMetadata.name + "." + requestMetadataEntry.key.lowercased()
            ] = .string(requestMetadataEntry.value.encoded())  // encodes binary data in base64
        }

        return metadata
    }
}
