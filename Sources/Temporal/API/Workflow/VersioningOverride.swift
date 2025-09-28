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

/// Used to override the versioning behavior (and pinned deployment version, if applicable) of a specific workflow execution.
///
/// If set, takes precedence over the worker-sent values. See `WorkflowExecutionInfo.VersioningInfo` for more information. To remove the override, call `UpdateWorkflowExecutionOptions` with a null `VersioningOverride`, and use the `update_mask` to indicate that it should be mutated.
public struct VersioningOverride: Hashable, Sendable {
    public var behavior: VersioningBehavior

    /// Required if behavior is `PINNED`.
    ///
    /// Must be null if behavior is `AUTO_UPGRADE`. Identifies the worker deployment to pin the workflow to.
    /// Deprecated. Use `pinned_version`.
    ///
    /// NOTE: This field was marked as deprecated in the .proto file.
    public var deployment: Deployment?

    /// Required if behavior is `PINNED`.
    ///
    /// Must be absent if behavior is not `PINNED`. Identifies the worker deployment version to pin the workflow to, in the format "<deployment_name>.<build_id>".
    public var pinnedVersion: String?

    public init(behavior: VersioningBehavior, deployment: Deployment? = nil, pinnedVersion: String? = nil) {
        self.behavior = behavior
        self.deployment = deployment
        self.pinnedVersion = pinnedVersion
    }
}
