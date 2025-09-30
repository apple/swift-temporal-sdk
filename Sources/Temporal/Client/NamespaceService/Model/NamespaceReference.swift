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

/// Provides methods for identifying a Temporal namespace in API operations.
public enum NamespaceReference: Hashable, Sendable {
    /// Identifies the namespace using its human-readable name.
    case name(String)

    /// Identifies the namespace using its unique system-generated identifier.
    case id(String)
}
