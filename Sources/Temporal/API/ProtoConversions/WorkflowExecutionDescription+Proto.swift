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

import SwiftProtobuf

extension WorkflowExecutionDescription {
    init(_ raw: Temporal_Api_Workflowservice_V1_DescribeWorkflowExecutionResponse, dataConverter: DataConverter) throws {
        self.execution = try .init(raw.workflowExecutionInfo, dataConverter: dataConverter)
        self.pendingActivities = raw.pendingActivities.map { .init($0) }
    }
}

extension PendingActivityInfo {
    init(_ raw: Temporal_Api_Workflow_V1_PendingActivityInfo) {
        self.activityID = raw.activityID
        self.activityType = .init(raw.activityType)
        self.heartbeatDetails = raw.heartbeatDetails.payloads.map { TemporalPayload(temporalAPIPayload: $0) }
        self.lastHeartbeatTime = raw.lastHeartbeatTime.date
        self.lastStartedTime = raw.lastStartedTime.date
        self.state = .init(raw.state)
    }
}

extension ActivityType {
    init(_ raw: Temporal_Api_Common_V1_ActivityType) {
        self.name = raw.name
    }
}

extension PendingActivityState {
    init(_ raw: Temporal_Api_Enums_V1_PendingActivityState) {
        switch raw {
        case .unspecified: self = .unspecified
        case .scheduled: self = .scheduled
        case .started: self = .started
        case .cancelRequested: self = .cancelRequested
        case .paused: self = .paused
        case .pauseRequested: self = .pauseRequested
        case .UNRECOGNIZED(let int):
            fatalError("Unexpected raw value \(int) for \(PendingActivityState.self) from \(Temporal_Api_Enums_V1_PendingActivityState.self).")
        }
    }
}
