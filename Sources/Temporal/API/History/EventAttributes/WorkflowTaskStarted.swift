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

import struct Foundation.Date

extension HistoryEvent.Attributes {
    /// Event attributes for when a workflow task has started.
    public struct WorkflowTaskStarted: Hashable, Sendable {
        /// The id of the `WORKFLOW_TASK_SCHEDULED` event this task corresponds to.
        public var scheduledEventID: Int

        /// Identity of the worker who picked up this task.
        public var identity: String?

        public var requestID: String?

        /// True if this workflow should continue-as-new soon because its history size (in
        /// either event count or bytes) is getting large.
        public var suggestContinueAsNew: Bool

        /// Total history size in bytes, which the workflow might use to decide when to continue-as-new regardless of the suggestion.
        ///
        /// Note that history event count is just the event id of this event, so we don't include it explicitly here.
        public var historySizeBytes: Int

        /// Version info of the worker to whom this task was dispatched.
        /// - Note: Deprecated - This field is no longer used.
        public var workerVersion: WorkerVersionStamp?

        /// Used by server internally to properly reapply build ID redirects to an execution
        /// when rebuilding it from events.
        /// - Note: Deprecated - This field is no longer used.
        public var buildIDRedirectCounter: Int

        /// Creates event attributes for when a workflow task has started.
        public init(
            scheduledEventID: Int,
            identity: String? = nil,
            requestID: String? = nil,
            suggestContinueAsNew: Bool,
            historySizeBytes: Int,
            workerVersion: WorkerVersionStamp? = nil,
            buildIDRedirectCounter: Int
        ) {
            self.scheduledEventID = scheduledEventID
            self.identity = identity
            self.requestID = requestID
            self.suggestContinueAsNew = suggestContinueAsNew
            self.historySizeBytes = historySizeBytes
            self.workerVersion = workerVersion
            self.buildIDRedirectCounter = buildIDRedirectCounter
        }
    }
}
