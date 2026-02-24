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

import Foundation

import struct SwiftProtobuf.Google_Protobuf_Timestamp

extension Coresdk.WorkflowCommands.ScheduleLocalActivity {
    init(
        id: UInt32,
        activityType: String,
        headers: [String: Api.Common.V1.Payload],
        input: [Api.Common.V1.Payload],
        options: LocalActivityOptions,
        attempt: UInt32?,
        originalScheduleTime: Google_Protobuf_Timestamp?
    ) {
        self = .init()
        self.seq = id
        self.activityType = activityType
        self.activityID = options.activityID ?? String(id)
        self.arguments = input
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
            self.headers = headers
        }
        if let attempt {
            self.attempt = attempt
        }
        if let originalScheduleTime {
            self.originalScheduleTime = originalScheduleTime
        }
    }
}
