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

/// Defines the operational configuration settings for a Temporal namespace.
public struct NamespaceConfig: Hashable, Sendable {
    /// The duration for which workflow execution data is retained in active storage.
    public var workflowExecutionRetentionTtl: Duration?

    /// Information about problematic binary versions that should be avoided.
    public var badBinaries: NamespaceBadBinaries?

    /// The archival configuration for workflow execution histories.
    public var historyArchivalState: NamespaceArchivalState?

    /// The archival configuration for workflow visibility records.
    public var visibilityArchivalState: NamespaceArchivalState?

    /// Custom mappings for search attribute names to provide more intuitive aliases.
    public var customSearchAttributeAliases: [String: String]?

    /// Creates a new namespace configuration with the specified settings.
    ///
    /// - Parameters:
    ///   - workflowExecutionRetentionTtl: How long to retain workflow data in active storage.
    ///   - badBinaries: Information about problematic binary versions to track.
    ///   - historyArchivalState: Long-term storage configuration for workflow histories.
    ///   - visibilityArchivalState: Long-term storage configuration for visibility records.
    ///   - customSearchAttributeAliases: Custom mappings for search attribute names.
    public init(
        workflowExecutionRetentionTtl: Duration? = nil,
        badBinaries: NamespaceBadBinaries? = nil,
        historyArchivalState: NamespaceArchivalState? = nil,
        visibilityArchivalState: NamespaceArchivalState? = nil,
        customSearchAttributeAliases: [String: String]? = nil
    ) {
        self.workflowExecutionRetentionTtl = workflowExecutionRetentionTtl
        self.badBinaries = badBinaries
        self.historyArchivalState = historyArchivalState
        self.visibilityArchivalState = visibilityArchivalState
        self.customSearchAttributeAliases = customSearchAttributeAliases
    }
}
