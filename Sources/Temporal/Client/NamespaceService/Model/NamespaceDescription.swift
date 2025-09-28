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

/// Provides a comprehensive description of a Temporal namespace and its configuration.
public struct NamespaceDescription: Hashable, Sendable {
    /// Core information about the namespace including name, state, and capabilities.
    public var info: NamespaceInfo

    /// Operational configuration settings for the namespace.
    public var config: NamespaceConfig

    /// Multi-cluster replication configuration for the namespace.
    public var replicationConfig: NamespaceReplicationConfig

    /// A Boolean value that indicates whether this namespace operates across multiple clusters.
    public var isGlobalNamespace: Bool

    /// The current failover version number for this namespace.
    public var failoverVersion: Int

    /// A chronological record of failover events for this namespace.
    public var failoverHistory: [NamespaceFailoverStatus]
}
