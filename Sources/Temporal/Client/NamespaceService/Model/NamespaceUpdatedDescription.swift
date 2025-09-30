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

/// Contains the complete updated description of a namespace after modification.
public struct NamespaceUpdatedDescription: Hashable, Sendable {
    /// The current namespace information including any updates that were applied.
    public var info: NamespaceInfo

    /// The current operational configuration for the namespace.
    public var config: NamespaceConfig

    /// The current multi-cluster replication configuration.
    public var replicationConfig: NamespaceReplicationConfig

    /// The current failover version number for this namespace.
    public var failoverVersion: Int

    /// A boolean value indicating whether this namespace operates across multiple clusters.
    public var isGlobalNamespace: Bool
}
