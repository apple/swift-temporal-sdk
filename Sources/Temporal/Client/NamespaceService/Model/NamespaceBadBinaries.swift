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

/// Contains information about problematic binary versions within a namespace.
public struct NamespaceBadBinaries: Hashable, Sendable {
    /// A dictionary mapping binary identifiers to their associated problem information.
    public var binaries: [String: Self.Info]
}

extension NamespaceBadBinaries {
    /// Detailed information about a specific problematic binary version.
    public struct Info: Hashable, Sendable {
        /// A human-readable explanation of why this binary version is considered problematic.
        public var reason: String?

        /// The identifier of the operator or system that marked this binary as bad.
        public var `operator`: String?

        /// The timestamp when this binary was first identified as problematic.
        public var createdAt: Date?
    }
}
