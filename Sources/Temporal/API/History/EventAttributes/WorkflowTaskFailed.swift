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

extension HistoryEvent.Attributes {
    /// Event attributes for when a workflow task has failed.
    public struct WorkflowTaskFailed: Hashable, Sendable {
        /// The id of the `WORKFLOW_TASK_SCHEDULED` event this task corresponds to.
        public var scheduledEventID: Int

        /// The id of the `WORKFLOW_TASK_STARTED` event this task corresponds to.
        public var startedEventID: Int

        /// The cause of the workflow task failure.
        public var cause: WorkflowTaskFailedCause

        /// The failure details.
        public var failure: Api.Failure.V1.Failure

        /// If a worker explicitly failed this task, it's identity.
        public var identity: String?

        /// The original run id of the workflow.
        ///
        /// For reset workflow.
        public var baseRunID: String?

        /// If the workflow is being reset, the new run id.
        public var newRunID: String?

        public var forkEventVersion: Int

        /// If a worker explicitly failed this task, its binary id.
        /// - Note: Deprecated - Use the info inside the corresponding WorkflowTaskStartedEvent.
        public var binaryChecksum: String?

        /// Version info of the worker who processed this workflow task.
        ///
        /// If present, the `build_id` field within is also used as `binary_checksum`, which may be omitted in that case (it may also be populated to preserve compatibility).
        /// - Note: Deprecated - Use the info inside the corresponding WorkflowTaskStartedEvent.
        public var workerVersion: WorkerVersionStamp?

        /// Creates event attributes for when a workflow task has failed.
        public init(
            scheduledEventID: Int,
            startedEventID: Int,
            cause: WorkflowTaskFailedCause = .unspecified,
            failure: Api.Failure.V1.Failure,
            identity: String? = nil,
            baseRunID: String? = nil,
            newRunID: String? = nil,
            forkEventVersion: Int,
            binaryChecksum: String? = nil,
            workerVersion: WorkerVersionStamp? = nil
        ) {
            self.scheduledEventID = scheduledEventID
            self.startedEventID = startedEventID
            self.cause = cause
            self.failure = failure
            self.identity = identity
            self.baseRunID = baseRunID
            self.newRunID = newRunID
            self.forkEventVersion = forkEventVersion
            self.binaryChecksum = binaryChecksum
            self.workerVersion = workerVersion
        }
    }
}
