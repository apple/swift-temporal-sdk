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
    /// Event attributes for when an activity task has been scheduled.
    public struct ActivityTaskScheduled: Hashable, Sendable {
        /// The worker/user assigned identifier for the activity.
        public var activityID: String

        /// The type name of the activity to execute.
        public var activityType: String

        /// The task queue on which the activity should be scheduled.
        public var taskQueue: TaskQueue

        /// Headers to pass to the activity.
        public var headers: [String: TemporalPayload]

        /// Input arguments for the activity.
        public var input: [TemporalPayload]

        /// Indicates how long the caller is willing to wait for an activity completion.
        ///
        /// Limits how long retries will be attempted. Either this or `start_to_close_timeout` must be specified.
        public var scheduleToCloseTimeout: Duration?

        /// Limits time an activity task can stay in a task queue before a worker picks it up.
        ///
        /// This timeout is always non retryable, as all a retry would achieve is to put it back into the same
        /// queue. Defaults to `schedule_to_close_timeout` or workflow execution timeout if not specified.
        public var scheduleToStartTimeout: Duration?

        /// Maximum time an activity is allowed to execute after being picked up by a worker.
        ///
        /// This timeout is always retryable. Either this or `schedule_to_close_timeout` must be specified.
        public var startToCloseTimeout: Duration?

        /// Maximum permitted time between successful worker heartbeats.
        public var heartbeatTimeout: Duration?

        /// The `WORKFLOW_TASK_COMPLETED` event which this command was reported with.
        public var workflowTaskCompletedEventID: Int

        /// Activities are assigned a default retry policy controlled by the service's dynamic configuration.
        ///
        /// Retries will happen up to `schedule_to_close_timeout`. To disable retries set retry_policy.maximum_attempts to 1.
        public var retryPolicy: RetryPolicy?

        /// If this is set, the activity would be assigned to the Build ID of the workflow.
        ///
        /// Otherwise, Assignment rules of the activity's Task Queue will be used to determine the Build ID.
        public var useWorkflowBuildID: Bool

        /// Priority metadata.
        ///
        /// If this message is not present, or any fields are not present, they inherit the values from the workflow.
        public var priority: Priority?

        /// Creates event attributes for when an activity task has been scheduled.
        public init(
            activityID: String,
            activityType: String,
            taskQueue: TaskQueue,
            headers: [String: TemporalPayload],
            input: [TemporalPayload],
            scheduleToCloseTimeout: Duration? = nil,
            scheduleToStartTimeout: Duration? = nil,
            startToCloseTimeout: Duration? = nil,
            heartbeatTimeout: Duration? = nil,
            workflowTaskCompletedEventID: Int,
            retryPolicy: RetryPolicy? = nil,
            useWorkflowBuildID: Bool,
            priority: Priority? = nil
        ) {
            self.activityID = activityID
            self.activityType = activityType
            self.taskQueue = taskQueue
            self.headers = headers
            self.input = input
            self.scheduleToCloseTimeout = scheduleToCloseTimeout
            self.scheduleToStartTimeout = scheduleToStartTimeout
            self.startToCloseTimeout = startToCloseTimeout
            self.heartbeatTimeout = heartbeatTimeout
            self.workflowTaskCompletedEventID = workflowTaskCompletedEventID
            self.retryPolicy = retryPolicy
            self.useWorkflowBuildID = useWorkflowBuildID
            self.priority = priority
        }
    }
}
