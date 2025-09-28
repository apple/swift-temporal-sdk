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

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// Represents the archival configuration options for namespace data storage.
public enum NamespaceArchivalState: Hashable, Sendable {
    /// Archival is enabled and data will be stored at the specified URL.
    case enabled(URL)

    /// Archival is disabled and data will not be preserved beyond the retention period.
    case disabled
}
