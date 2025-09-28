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

/// Defines the multi-cluster replication configuration for a Temporal namespace.
public struct NamespaceReplicationConfig: Hashable, Sendable {
    /// The name of the cluster that is currently active and handling write operations.
    public var activeClusterName: String?

    /// The list of all clusters participating in namespace replication.
    public var clusters: [String]

    /// The current state of the replication process.
    public var state: ReplicationState?

    /// Creates a new replication configuration for a namespace.
    ///
    /// - Parameters:
    ///   - activeClusterName: The cluster that should handle write operations.
    ///   - clusters: All clusters that should participate in replication.
    ///   - state: The initial replication state, if known.
    public init(
        activeClusterName: String? = nil,
        clusters: [String],
        state: ReplicationState? = nil
    ) {
        self.activeClusterName = activeClusterName
        self.clusters = clusters
        self.state = state
    }
}
