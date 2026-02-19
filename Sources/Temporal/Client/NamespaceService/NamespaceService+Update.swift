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
    /// Updates the configuration and information of a registered namespace.
    ///
    /// This method allows you to modify various aspects of an existing namespace,
    /// including its metadata, configuration settings, replication setup, and
    /// operational state. You can update multiple aspects simultaneously or
    /// individually by providing only the parameters you wish to change.
    ///
    /// - Parameters:
    ///   - namespace: The name of the namespace to update.
    ///   - updateInfo: Optional updates to namespace information like description and owner.
    ///   - config: Optional updates to namespace configuration including retention and archival settings.
    ///   - replicationConfig: Optional updates to replication settings for multi-cluster setups.
    ///   - securityToken: Optional security token if required by the namespace.
    ///   - deleteBadBinary: Optional binary version to remove from the namespace.
    ///   - promoteNamespace: If `true`, promotes a local namespace to global. Ignored if already global.
    ///   - callOptions: Optional gRPC call options for customizing the behavior of the underlying request.
    /// - Returns: The updated namespace description with all current settings.
    /// - Throws: ``TemporalError`` if the update fails, invalid transitions, or insufficient permissions.
    public func updateNamespace(
        namespace: String,
        updateInfo: NamespaceUpdateInfo? = nil,
        config: NamespaceConfig? = nil,
        replicationConfig: NamespaceReplicationConfig? = nil,
        securityToken: String? = nil,
        deleteBadBinary: String? = nil,
        promoteNamespace: Bool? = nil,
        callOptions: CallOptions? = nil
    ) async throws -> NamespaceUpdatedDescription {
        let response: Api.Workflowservice.V1.UpdateNamespaceResponse = try await self.client.unary(
            method: Api.Workflowservice.V1.WorkflowService.Method.UpdateNamespace.descriptor,
            request: Api.Workflowservice.V1.UpdateNamespaceRequest.with {
                $0.namespace = namespace
                if let updateInfo {
                    $0.updateInfo = .init(updateInfo: updateInfo)
                }
                if let config {
                    $0.config = .init(config: config)
                }
                if let replicationConfig {
                    $0.replicationConfig = .init(replicationConfig: replicationConfig)
                }
                if let securityToken {
                    $0.securityToken = securityToken
                }
                if let deleteBadBinary {
                    $0.deleteBadBinary = deleteBadBinary
                }
                if let promoteNamespace {
                    $0.promoteNamespace = promoteNamespace
                }
            },
            callOptions: callOptions
        )

        return .init(proto: response)
    }
}
