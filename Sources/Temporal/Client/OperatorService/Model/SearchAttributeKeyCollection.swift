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

/// Contains information about search attributes in a Temporal namespace.
public struct SearchAttributeKeyCollection: Hashable, Sendable {
    /// Mapping of custom (user-registered) search attribute names to their data types.
    public var customAttributes: [String: SearchAttributeType]

    /// Mapping of system (predefined) search attribute names to their data types.
    public var systemAttributes: [String: SearchAttributeType]

    /// Mapping from attribute names to their native storage types in the visibility store.
    public var storageSchema: [String: String]
}
