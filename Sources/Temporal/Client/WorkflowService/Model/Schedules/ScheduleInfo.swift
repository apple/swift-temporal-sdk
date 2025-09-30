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

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// Runtime information and operational metrics for a workflow schedule.
public struct ScheduleInfo: Hashable, Sendable {
    /// The total number of actions successfully triggered by this schedule.
    public var numActions: Int

    /// The number of actions that were skipped because they missed their catchup window.
    public var numActionsMissedCatchupWindow: Int

    /// The number of actions that were skipped due to overlap policy restrictions.
    public var numActionsSkippedOverlap: Int

    /// The number of actions that were dropped due to buffer capacity limits.
    public var numActionsBufferDropped: Int

    /// The current number of actions waiting in the execution buffer.
    public var numActionsInBuffer: Int

    /// Currently executing workflow instances triggered by this schedule.
    public var runningActions: [ActionExecution]

    /// The ten most recent action executions, ordered from oldest to newest.
    public var recentActions: [ActionResult]

    /// The next ten scheduled action times based on the current schedule specification.
    public var nextActionTimes: [Date]

    /// The timestamp when this schedule was originally created.
    public var createdAt: Date

    /// The timestamp of the most recent schedule update, if any updates have occurred.
    public var lastUpdatedAt: Date?

    /// Creates runtime information for a workflow schedule.
    ///
    /// - Parameters:
    ///   - numActions: Total number of actions successfully triggered.
    ///   - numActionsMissedCatchupWindow: Actions skipped due to missing catchup windows.
    ///   - numActionsSkippedOverlap: Actions skipped due to overlap policy restrictions.
    ///   - numActionsBufferDropped: Actions dropped due to buffer capacity limits.
    ///   - numActionsInBuffer: Current number of buffered actions awaiting execution.
    ///   - runningActions: Currently executing workflow instances.
    ///   - recentActions: Ten most recent action executions with outcomes.
    ///   - nextActionTimes: Next ten scheduled execution times.
    ///   - createdAt: Timestamp when the schedule was created.
    ///   - lastUpdatedAt: Timestamp of the most recent update, if any.
    package init(
        numActions: Int,
        numActionsMissedCatchupWindow: Int,
        numActionsSkippedOverlap: Int,
        numActionsBufferDropped: Int,
        numActionsInBuffer: Int,
        runningActions: [ActionExecution],
        recentActions: [ActionResult],
        nextActionTimes: [Date],
        createdAt: Date,
        lastUpdatedAt: Date?
    ) {
        self.numActions = numActions
        self.numActionsMissedCatchupWindow = numActionsMissedCatchupWindow
        self.numActionsSkippedOverlap = numActionsSkippedOverlap
        self.numActionsBufferDropped = numActionsBufferDropped
        self.numActionsInBuffer = numActionsInBuffer
        self.runningActions = runningActions
        self.recentActions = recentActions
        self.nextActionTimes = nextActionTimes
        self.createdAt = createdAt
        self.lastUpdatedAt = lastUpdatedAt
    }
}
