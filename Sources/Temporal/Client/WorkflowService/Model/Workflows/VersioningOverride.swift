//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Temporal SDK open source project
//
// Copyright (c) 2026 Apple Inc. and the Swift Temporal SDK project authors
// Licensed under MIT License
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Swift Temporal SDK project authors
//
// SPDX-License-Identifier: MIT
//
//===----------------------------------------------------------------------===//

/// Override for a workflow's versioning behavior.
///
/// Versioning overrides control how a workflow execution interacts with worker deployment versions.
/// A workflow can either be pinned to a specific deployment version or set to auto-upgrade to the
/// current deployment version on the next workflow task.
public struct VersioningOverride: Sendable {
    package enum Kind: Sendable {
        case pinned(deploymentVersion: DeploymentVersion)
        case autoUpgrade
    }

    package let kind: Kind

    private init(_ kind: Kind) { self.kind = kind }

    /// Pin the workflow to a specific deployment version.
    ///
    /// The workflow will remain on the specified version until the override is changed.
    ///
    /// - Parameter deploymentVersion: The deployment version to pin the workflow to.
    /// - Returns: A versioning override that pins the workflow to the given version.
    public static func pinned(deploymentVersion: DeploymentVersion) -> VersioningOverride {
        .init(.pinned(deploymentVersion: deploymentVersion))
    }

    /// Auto-upgrade the workflow to the current deployment version on the next workflow task.
    public static let autoUpgrade = VersioningOverride(.autoUpgrade)
}
