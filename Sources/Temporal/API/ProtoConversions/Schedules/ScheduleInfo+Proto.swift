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

extension ScheduleInfo {
    init(proto: Temporal_Api_Schedule_V1_ScheduleInfo) {
        self.numActions = Int(proto.actionCount)
        self.numActionsMissedCatchupWindow = Int(proto.missedCatchupWindow)
        self.numActionsSkippedOverlap = Int(proto.overlapSkipped)
        self.numActionsBufferDropped = Int(proto.bufferDropped)
        self.numActionsInBuffer = Int(proto.bufferSize)
        self.runningActions = proto.runningWorkflows.map { .init(proto: $0) }
        self.recentActions = proto.recentActions.map { .init(proto: $0) }
        self.nextActionTimes = proto.futureActionTimes.map { $0.date }
        self.createdAt = proto.createTime.date
        if proto.hasUpdateTime {
            self.lastUpdatedAt = proto.updateTime.date
        }
    }
}

extension ScheduleInfo.ActionExecution {
    init(proto: Temporal_Api_Common_V1_WorkflowExecution) {
        self.workflowId = proto.workflowID
        self.firstExecutionRunId = proto.runID
    }
}

extension ScheduleInfo.ActionResult {
    init(proto: Temporal_Api_Schedule_V1_ScheduleActionResult) {
        self.scheduledAt = proto.scheduleTime.date
        self.startedAt = proto.actualTime.date
        self.action = .init(proto: proto.startWorkflowResult)
        self.status = .init(temporalAPIWorkflowExecutionStatus: proto.startWorkflowStatus)
    }
}
