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
    /// Permanently deletes a namespace and reclaims all associated resources.
    ///
    /// This operation permanently removes a namespace from the Temporal cluster,
    /// including all workflow executions, task queues, and other resources within
    /// the namespace. The deletion process may be delayed to allow for cleanup
    /// operations and resource reclamation.
    ///
    /// - Parameters:
    ///   - namespace: The namespace identifier, either by name or ID.
    ///   - delay: Optional delay before deletion begins. If not provided, uses the cluster's default delay.
    ///   - callOptions: Optional gRPC call options for customizing the behavior of the underlying request.
    /// - Returns: The temporary namespace name used during the resource cleanup process.
    /// - Throws: An error if the deletion operation fails or if insufficient permissions.
    @discardableResult
    public func deleteNamespace(
        namespace: NamespaceReference,
        delay: Duration? = nil,
        callOptions: CallOptions? = nil
    ) async throws -> String {
        let response: Api.Operatorservice.V1.DeleteNamespaceResponse = try await self.client.unary(
            method: Api.Operatorservice.V1.OperatorService.Method.DeleteNamespace.descriptor,
            request: Api.Operatorservice.V1.DeleteNamespaceRequest.with {
                switch namespace {
                case .name(let namespaceName):
                    $0.namespace = namespaceName
                case .id(let namespaceID):
                    $0.namespaceID = namespaceID
                }
                if let delay {
                    $0.namespaceDeleteDelay = .init(duration: delay)
                }
            },
            callOptions: callOptions
        )

        return response.deletedNamespace
    }
}
