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

/// `Deployment` identifies a deployment of Temporal workers.
///
/// The combination of deployment series name + build ID serves as the identifier. User can use `WorkerDeploymentOptions` in their worker programs to specify these values.
/// Deprecated.
public struct Deployment: Hashable, Sendable {
    /// Different versions of the same worker service/application are related together by having a shared series name.
    ///
    /// Out of all deployments of a series, one can be designated as the current deployment, which receives new workflow executions and new tasks of workflows with `VERSIONING_BEHAVIOR_AUTO_UPGRADE` versioning behavior.
    public var seriesName: String

    /// Build ID changes with each version of the worker when the worker program code and/or config
    /// changes.
    public var buildID: String

    public init(seriesName: String, buildID: String) {
        self.seriesName = seriesName
        self.buildID = buildID
    }
}
