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

/// Versioning Behavior specifies if and how a workflow execution moves between Worker Deployment Versions.
///
/// The Versioning Behavior of a workflow execution is typically specified by the worker who completes the first task of the execution, but is also overridable manually for new and existing workflows (see VersioningOverride).
/// Experimental. Worker Deployments are experimental and might significantly change in the future.
public enum VersioningBehavior: Hashable, Sendable {
    /// Workflow execution does not have a Versioning Behavior and is called Unversioned. This is the
    /// legacy behavior. An Unversioned workflow's task can go to any Unversioned worker (see
    /// `WorkerVersioningMode`.)
    /// User needs to use Patching to keep the new code compatible with prior versions when dealing
    /// with Unversioned workflows.
    case unspecified

    /// Workflow will start on the Current Deployment Version of its Task Queue, and then
    /// will be pinned to that same Deployment Version until completion (the Version that
    /// this Workflow is pinned to is specified in `versioning_info.version`).
    /// This behavior eliminates most of compatibility concerns users face when changing their code.
    /// Patching is not needed when pinned workflows code change.
    /// Can be overridden explicitly via `UpdateWorkflowExecutionOptions` API to move the
    /// execution to another Deployment Version.
    /// Activities of `PINNED` workflows are sent to the same Deployment Version. Exception to this
    /// would be when the activity Task Queue workers are not present in the workflow's Deployment
    /// Version, in which case the activity will be sent to the Current Deployment Version of its own
    /// task queue.
    case pinned

    /// Workflow will automatically move to the Current Deployment Version of its Task Queue when the
    /// next workflow task is dispatched.
    /// AutoUpgrade behavior is suitable for long-running workflows as it allows them to move to the
    /// latest Deployment Version, but the user still needs to use Patching to keep the new code
    /// compatible with prior versions for changed workflow types.
    /// Activities of `AUTO_UPGRADE` workflows are sent to the Deployment Version of the workflow
    /// execution (as specified in versioning_info.version based on the last completed
    /// workflow task). Exception to this would be when the activity Task Queue workers are not
    /// present in the workflow's Deployment Version, in which case, the activity will be sent to a
    /// different Deployment Version according to the Current Deployment Version of its own task
    /// queue.
    /// Workflows stuck on a backlogged activity will still auto-upgrade if the Current Deployment
    /// Version of their Task Queue changes, without having to wait for the backlogged activity to
    /// complete on the old Version.
    case autoUpgrade
}
