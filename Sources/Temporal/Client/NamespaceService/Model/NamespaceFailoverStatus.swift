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

#if canImport(FoundationEssentials)
public import FoundationEssentials
#else
public import Foundation
#endif

/// Represents a historical record of namespace failover events in multi-cluster setups.
public struct NamespaceFailoverStatus: Hashable, Sendable {
    /// The timestamp when the namespace transitioned to the associated failover version.
    public var failoverTime: Date?

    /// The version number associated with this failover event.
    public var failoverVersion: Int
}
