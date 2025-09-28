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

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

extension ScheduleInfo {
    /// Represents a currently executing workflow instance started by a schedule.
    public struct ActionExecution: Hashable, Sendable {
        /// The unique identifier of the workflow execution started by the schedule.
        public var workflowId: String

        /// The initial run identifier for this workflow execution.
        public var firstExecutionRunId: String

        /// Creates execution information for a scheduled workflow start.
        ///
        /// - Parameters:
        ///   - workflowId: The unique identifier of the started workflow.
        ///   - firstExecutionRunId: The initial run ID for the workflow execution.
        package init(
            workflowId: String,
            firstExecutionRunId: String
        ) {
            self.workflowId = workflowId
            self.firstExecutionRunId = firstExecutionRunId
        }
    }

    /// Contains detailed information about a completed schedule action execution.
    public struct ActionResult: Hashable, Sendable {
        /// The originally scheduled time for this action, including any applied jitter.
        public var scheduledAt: Date

        /// The actual timestamp when the action execution began.
        public var startedAt: Date

        /// Details about the workflow execution that was started by this scheduled action.
        public var action: ActionExecution

        /// The final execution status of the workflow that was started by this action.
        public var status: WorkflowExecutionStatus?

        /// Creates detailed information about a completed schedule action execution.
        ///
        /// - Parameters:
        ///   - scheduledAt: The originally scheduled time including applied jitter.
        ///   - startedAt: The actual time when action execution began.
        ///   - action: Details about the workflow execution that was started.
        ///   - status: The final execution status, if the workflow has completed.
        package init(
            scheduledAt: Date,
            startedAt: Date,
            action: ActionExecution,
            status: WorkflowExecutionStatus?
        ) {
            self.scheduledAt = scheduledAt
            self.startedAt = startedAt
            self.action = action
            self.status = status
        }
    }
}
