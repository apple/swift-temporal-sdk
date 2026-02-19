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

import SwiftProtobuf

public import struct GRPCCore.CallOptions

extension TemporalClient.NamespaceService {
    /// Retrieves detailed information and configuration for a registered namespace.
    ///
    /// This method fetches comprehensive information about a namespace, including
    /// its configuration, state, replication settings, and operational details.
    /// The information is useful for monitoring, debugging, and managing namespace
    /// settings within your Temporal cluster.
    ///
    /// - Parameters:
    ///    - namespace: The namespace identifier, either by name or UUID.
    ///    - callOptions: Optional gRPC call options for customizing the behavior of the underlying request.
    /// - Returns: A complete description of the namespace configuration and state.
    /// - Throws: An error if the namespace doesn't exist or access is denied.
    public func describeNamespace(
        namespace: NamespaceReference,
        callOptions: CallOptions? = nil
    ) async throws -> NamespaceDescription {
        let response: Api.Workflowservice.V1.DescribeNamespaceResponse = try await self.client.unary(
            method: Api.Workflowservice.V1.WorkflowService.Method.DescribeNamespace.descriptor,
            request: Api.Workflowservice.V1.DescribeNamespaceRequest.with {
                switch namespace {
                case .name(let namespaceName):
                    $0.namespace = namespaceName
                case .id(let namespaceID):
                    $0.id = namespaceID
                }
            },
            callOptions: callOptions
        )

        return .init(proto: response)
    }
}
