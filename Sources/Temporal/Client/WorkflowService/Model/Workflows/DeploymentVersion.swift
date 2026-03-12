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

/// Represents a version of a worker within a Worker Deployment.
///
/// The combination of ``deploymentName`` and ``buildId`` uniquely identifies a version
/// within a namespace, because deployment names are unique within a namespace.
public struct DeploymentVersion: Sendable {
    /// Identifies the Worker Deployment this version is part of.
    public var deploymentName: String

    /// A unique identifier for this version within the Deployment it is a part of.
    ///
    /// Not necessarily unique within the namespace.
    public var buildId: String

    /// Creates a deployment version.
    ///
    /// - Parameters:
    ///   - deploymentName: Identifies the Worker Deployment this version is part of.
    ///   - buildId: A unique identifier for this version within the Deployment.
    public init(deploymentName: String, buildId: String) {
        self.deploymentName = deploymentName
        self.buildId = buildId
    }
}
