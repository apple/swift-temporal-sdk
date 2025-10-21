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

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

extension TemporalClient.NamespaceService {
    /// Creates a new Temporal namespace with the specified configuration.
    ///
    /// A namespace serves as a top-level container and isolation boundary for all
    /// Temporal resources including workflow executions, task queues, schedules,
    /// and other entities. Each namespace provides complete isolation from other
    /// namespaces and can have its own retention policies, replication settings,
    /// and access controls.
    ///
    /// - Parameters:
    ///   - name: The unique name for the new namespace.
    ///   - workflowExecutionRetentionPeriod: How long to retain workflow execution histories.
    ///   - description: Optional human-readable description of the namespace purpose.
    ///   - ownerEmail: Optional contact email for namespace ownership.
    ///   - clusters: Optional list of cluster names for multi-cluster replication.
    ///   - activeClusterName: Optional primary cluster name for global namespaces.
    ///   - data: Optional key-value metadata for application-specific information.
    ///   - securityToken: Optional security token for namespace access control.
    ///   - isGlobalNamespace: Optional flag indicating multi-cluster namespace.
    ///   - historyArchivalState: Optional configuration for long-term history storage.
    ///   - visibilityArchivalState: Optional configuration for visibility record archival.
    ///   - callOptions: Optional gRPC call options for customizing the behavior of the underlying request.
    /// - Throws: ``TemporalError`` if registration fails, name conflicts, or insufficient permissions.
    public func registerNamespace(
        name: String,
        workflowExecutionRetentionPeriod: Duration,
        description: String? = nil,
        ownerEmail: String? = nil,
        clusters: [String]? = nil,
        activeClusterName: String? = nil,
        data: [String: String]? = nil,
        securityToken: String? = nil,
        isGlobalNamespace: Bool? = nil,
        historyArchivalState: NamespaceArchivalState? = nil,
        visibilityArchivalState: NamespaceArchivalState? = nil,
        callOptions: CallOptions? = nil
    ) async throws {
        try await self.client.unary(
            method: Temporal_Api_Workflowservice_V1_WorkflowService.Method.RegisterNamespace.descriptor,
            request: Temporal_Api_Workflowservice_V1_RegisterNamespaceRequest.with {
                // only these two properties are mandatory
                $0.namespace = name
                $0.workflowExecutionRetentionPeriod = .init(duration: workflowExecutionRetentionPeriod)

                if let description {
                    $0.description_p = description
                }
                if let ownerEmail {
                    $0.ownerEmail = ownerEmail
                }
                if let clusters {
                    $0.clusters = clusters.map { clusterName in
                        .with {
                            $0.clusterName = clusterName
                        }
                    }
                }
                if let activeClusterName {
                    $0.activeClusterName = activeClusterName
                }
                if let data {
                    $0.data = data
                }
                if let securityToken {
                    $0.securityToken = securityToken
                }
                if let isGlobalNamespace {
                    $0.isGlobalNamespace = isGlobalNamespace
                }

                switch historyArchivalState {
                case .enabled(let url):
                    $0.historyArchivalState = .enabled
                    $0.historyArchivalUri = url.absoluteString
                case .disabled:
                    $0.historyArchivalState = .disabled
                case nil:
                    break
                }

                switch visibilityArchivalState {
                case .enabled(let url):
                    $0.visibilityArchivalState = .enabled
                    $0.visibilityArchivalUri = url.absoluteString
                case .disabled:
                    $0.visibilityArchivalState = .disabled
                case nil:
                    break
                }
            },
            callOptions: callOptions
        )
    }
}
