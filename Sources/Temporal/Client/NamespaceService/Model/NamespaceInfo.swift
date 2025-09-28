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

/// Contains core identity and metadata information for a Temporal namespace.
public struct NamespaceInfo: Hashable, Sendable {
    /// The human-readable name of the namespace.
    public var name: String

    /// The unique system-generated identifier for the namespace.
    public var id: String

    /// The current operational state of the namespace.
    public var state: Self.State?

    /// A human-readable description explaining the namespace's purpose.
    public var description: String?

    /// The email address of the namespace owner or responsible party.
    public var ownerEmail: String?

    /// Custom key-value metadata associated with the namespace.
    public var data: [String: String]

    /// Feature capabilities supported by this namespace.
    public var capabilities: Self.Capabilities

    /// A Boolean value that indicates whether scheduled workflows are supported.
    public var supportsSchedules: Bool
}

extension NamespaceInfo {
    /// Represents the operational state of a namespace within its lifecycle.
    public enum State: Hashable, Sendable {
        /// The namespace is active and fully operational.
        case registered

        /// The namespace is marked as deprecated and should not be used for new workflows.
        case deprecated

        /// The namespace has been deleted and is no longer available.
        case deleted
    }
}

extension NamespaceInfo {
    /// Describes the feature capabilities available within a namespace.
    public struct Capabilities: Hashable, Sendable {
        /// A Boolean value that indicates whether eager workflow start is supported.
        public var eagerWorkflowStart: Bool

        /// A Boolean value that indicates whether synchronous workflow updates are supported.
        public var syncUpdate: Bool

        /// A Boolean value that indicates whether asynchronous workflow updates are supported.
        public var asyncUpdate: Bool
    }
}
