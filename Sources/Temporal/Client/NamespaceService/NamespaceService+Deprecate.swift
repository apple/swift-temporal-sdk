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

import struct GRPCCore.CallOptions

extension TemporalClient.NamespaceService {
    /// Updates a namespace state to deprecated, preventing new workflow executions.
    ///
    /// Deprecating a namespace prevents new workflow executions from being started
    /// within that namespace while allowing existing workflows to continue running
    /// until completion. This provides a graceful way to phase out a namespace
    /// without disrupting ongoing operations.
    ///
    /// - Parameters:
    ///   - namespace: The name of the namespace to deprecate.
    ///   - securityToken: Optional security token if the namespace requires it for updates.
    ///   - callOptions: Optional gRPC call options for customizing the behavior of the underlying request.
    /// - Throws: An error if the deprecation fails or authentication is insufficient.
    public func deprecateNamespace(
        namespace: String,
        securityToken: String? = nil,
        callOptions: CallOptions? = nil
    ) async throws {
        try await self.client.unary(
            method: Temporal_Api_Workflowservice_V1_WorkflowService.Method.UpdateNamespace.descriptor,
            request: Temporal_Api_Workflowservice_V1_UpdateNamespaceRequest.with {
                $0.namespace = namespace
                $0.updateInfo.state = .deprecated
                if let securityToken {
                    $0.securityToken = securityToken
                }
            },
            callOptions: callOptions
        )
    }
}
