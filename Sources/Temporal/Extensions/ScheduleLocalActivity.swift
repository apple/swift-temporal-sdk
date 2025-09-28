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

import Foundation

import struct SwiftProtobuf.Google_Protobuf_Timestamp

extension Coresdk_WorkflowCommands_ScheduleLocalActivity {
    init(
        id: UInt32,
        activityType: String,
        headers: [String: TemporalPayload],
        input: [TemporalPayload],
        options: LocalActivityOptions,
        attempt: UInt32?,
        originalScheduleTime: Google_Protobuf_Timestamp?
    ) {
        self.seq = id
        self.activityType = activityType
        self.activityID = options.activityID ?? String(id)
        self.arguments = input.map { .init(temporalPayload: $0) }
        self.cancellationType = .init(cancellationType: options.cancellationType)

        if let scheduleToCloseTimeout = options.scheduleToCloseTimeout {
            self.scheduleToCloseTimeout = .init(duration: scheduleToCloseTimeout)
        }
        if let scheduleToStartTimeout = options.scheduleToStartTimeout {
            self.scheduleToStartTimeout = .init(duration: scheduleToStartTimeout)
        }
        if let startToCloseTimeout = options.startToCloseTimeout {
            self.startToCloseTimeout = .init(duration: startToCloseTimeout)
        }
        if let retryPolicy = options.retryPolicy {
            self.retryPolicy = .init(retryPolicy: retryPolicy)
        }
        if !headers.isEmpty {
            self.headers = headers.mapValues { .init(temporalPayload: $0) }
        }
        if let attempt {
            self.attempt = attempt
        }
        if let originalScheduleTime {
            self.originalScheduleTime = originalScheduleTime
        }
    }
}
