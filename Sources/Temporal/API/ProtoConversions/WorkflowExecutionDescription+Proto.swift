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
    init(_ raw: Api.Workflowservice.V1.DescribeWorkflowExecutionResponse, dataConverter: DataConverter) throws {
        self.execution = try .init(raw.workflowExecutionInfo, dataConverter: dataConverter)
        self.pendingActivities = raw.pendingActivities.map { .init($0) }
    }
}

extension PendingActivityInfo {
    init(_ raw: Api.Workflow.V1.PendingActivityInfo) {
        self.activityID = raw.activityID
        self.activityType = .init(raw.activityType)
        self.heartbeatDetails = raw.heartbeatDetails.payloads.map { TemporalPayload(temporalAPIPayload: $0) }
        self.lastHeartbeatTime = raw.lastHeartbeatTime.date
        self.lastStartedTime = raw.lastStartedTime.date
        self.state = .init(raw.state)
    }
}

extension ActivityType {
    init(_ raw: Api.Common.V1.ActivityType) {
        self.name = raw.name
    }
}

extension PendingActivityState {
    init(_ raw: Api.Enums.V1.PendingActivityState) {
        switch raw {
        case .unspecified: self = .unspecified
        case .scheduled: self = .scheduled
        case .started: self = .started
        case .cancelRequested: self = .cancelRequested
        case .paused: self = .paused
        case .pauseRequested: self = .pauseRequested
        case .UNRECOGNIZED(let int):
            fatalError("Unexpected raw value \(int) for \(PendingActivityState.self) from \(Api.Enums.V1.PendingActivityState.self).")
        }
    }
}
