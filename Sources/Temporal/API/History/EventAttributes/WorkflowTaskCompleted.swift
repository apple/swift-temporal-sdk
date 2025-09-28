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

extension HistoryEvent.Attributes {
    /// Event attributes for when a workflow task has completed.
    public struct WorkflowTaskCompleted: Hashable, Sendable {
        /// The id of the `WORKFLOW_TASK_SCHEDULED` event this task corresponds to.
        public var scheduledEventID: Int

        /// The id of the `WORKFLOW_TASK_STARTED` event this task corresponds to.
        public var startedEventID: Int

        /// Identity of the worker who completed this task.
        public var identity: String?

        /// Binary ID of the worker who completed this task.
        public var binaryChecksum: String?

        /// Version info of the worker who processed this workflow task.
        ///
        /// If present, the `build_id` field within is also used as `binary_checksum`, which may be omitted in that case (it may also be populated to preserve compatibility).
        /// - Note: Deprecated - Use `deployment` and `versioningBehavior` instead.
        public var workerVersion: WorkerVersionStamp?

        /// Data the SDK wishes to record for itself, but server need not interpret, and does not
        /// directly impact workflow state.
        public var sdkMetadata: WorkflowTaskCompletedMetadata?

        /// Local usage data sent during workflow task completion and recorded here for posterity.
        public var meteringMetadata: MeteringMetadata

        /// The deployment that completed this task.
        ///
        /// May or may not be set for unversioned workers, depending on whether a value is sent by the SDK. This value updates workflow execution's `versioning_info.deployment`.
        /// - Note: Deprecated - Replaced with `workerDeploymentVersion`.
        public var deployment: Deployment?

        /// Versioning behavior sent by the worker that completed this task for this particular workflow execution.
        ///
        /// UNSPECIFIED means the task was completed by an unversioned worker. This value updates workflow execution's `versioning_info.behavior`.
        public var versioningBehavior: VersioningBehavior

        /// The Worker Deployment Version that completed this task.
        ///
        /// Must be set if `versioning_behavior` is set. This value updates workflow execution's `versioning_info.version`.
        /// Experimental. Worker Deployments are experimental and might significantly change in the future.
        public var workerDeploymentVersion: String?

        /// The name of Worker Deployment that completed this task.
        ///
        /// Must be set if `versioning_behavior` is set. This value updates workflow execution's `worker_deployment_name`.
        /// Experimental. Worker Deployments are experimental and might significantly change in the future.
        public var workerDeploymentName: String? = nil

        /// Creates event attributes for when a workflow task has completed.
        public init(
            scheduledEventID: Int,
            startedEventID: Int,
            identity: String? = nil,
            binaryChecksum: String?,
            workerVersion: WorkerVersionStamp? = nil,
            sdkMetadata: WorkflowTaskCompletedMetadata? = nil,
            meteringMetadata: MeteringMetadata,
            deployment: Deployment? = nil,
            versioningBehavior: VersioningBehavior = .unspecified,
            workerDeploymentVersion: String? = nil,
            workerDeploymentName: String? = nil
        ) {
            self.scheduledEventID = scheduledEventID
            self.startedEventID = startedEventID
            self.identity = identity
            self.binaryChecksum = binaryChecksum
            self.workerVersion = workerVersion
            self.sdkMetadata = sdkMetadata
            self.meteringMetadata = meteringMetadata
            self.deployment = deployment
            self.versioningBehavior = versioningBehavior
            self.workerDeploymentVersion = workerDeploymentVersion
            self.workerDeploymentName = workerDeploymentName
        }
    }
}
