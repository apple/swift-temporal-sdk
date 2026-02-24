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
public import FoundationEssentials
#else
public import Foundation
#endif

/// Information about an activity currently scheduled or running in a workflow.
public struct PendingActivityInfo: Hashable, Sendable {
    /// The unique identifier of the activity within the workflow.
    public var activityID: String
    /// The type of the activity, including its registered name.
    public var activityType: ActivityType
    /// The current execution state of the activity.
    public var state: PendingActivityState
    /// The most recent heartbeat details sent by the activity.
    public var heartbeatDetails: [Api.Common.V1.Payload]
    /// The timestamp when the most recent heartbeat was recorded.
    public var lastHeartbeatTime: Date
    /// The timestamp when the activity most recently started execution.
    public var lastStartedTime: Date

    // TODO: Incorporate remaining properties from `Api.Workflow.V1.PendingActivityInfo`
}
