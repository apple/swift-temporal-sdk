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
    /// Event attributes for when an activity task has completed.
    public struct ActivityTaskCompleted: Hashable, Sendable {
        /// Serialized results of the activity.
        ///
        /// IE: The return value of the activity function.
        public var result: [Api.Common.V1.Payload]

        /// The id of the `ACTIVITY_TASK_SCHEDULED` event this completion corresponds to.
        public var scheduledEventID: Int

        /// The id of the `ACTIVITY_TASK_STARTED` event this completion corresponds to.
        public var startedEventID: Int

        /// id of the worker that completed this task.
        public var identity: String?

        /// Version info of the worker who processed this workflow task.
        /// - Note: Deprecated - Use the info inside the corresponding ActivityTaskStartedEvent.
        public var workerVersion: WorkerVersionStamp?

        /// Creates event attributes for when an activity task has completed.
        public init(
            result: [Api.Common.V1.Payload],
            scheduledEventID: Int,
            startedEventID: Int,
            identity: String? = nil,
            workerVersion: WorkerVersionStamp? = nil
        ) {
            self.result = result
            self.scheduledEventID = scheduledEventID
            self.startedEventID = startedEventID
            self.identity = identity
            self.workerVersion = workerVersion
        }
    }
}
