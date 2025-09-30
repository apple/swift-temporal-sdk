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

/// Specifies updates to namespace information and metadata.
public struct NamespaceUpdateInfo: Hashable, Sendable {
    /// An updated human-readable description of the namespace's purpose.
    public var description: String?

    /// An updated email address for the namespace owner or responsible party.
    public var ownerEmail: String?

    /// Custom key-value metadata to merge with existing namespace data.
    public var data: [String: String]?

    /// The new operational state to transition the namespace to.
    public var state: NamespaceInfo.State?

    /// Creates a new update specification for namespace information.
    ///
    /// - Parameters:
    ///   - description: New description text for the namespace.
    ///   - ownerEmail: Updated owner email address.
    ///   - data: Custom metadata to merge with existing data.
    ///   - state: New operational state for the namespace.
    public init(
        description: String? = nil,
        ownerEmail: String? = nil,
        data: [String: String]? = nil,
        state: NamespaceInfo.State? = nil
    ) {
        self.description = description
        self.ownerEmail = ownerEmail
        self.data = data
        self.state = state
    }
}
