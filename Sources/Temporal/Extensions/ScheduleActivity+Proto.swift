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

extension Coresdk.WorkflowCommands.ScheduleActivity {
    init(
        id: UInt32,
        activityType: String,
        workflowTaskQueue: String,
        headers: [String: TemporalPayload],
        input: [TemporalPayload],
        options: ActivityOptions
    ) {
        self = .init()
        self.seq = id
        self.activityType = activityType
        self.activityID = options.activityID ?? String(id)
        self.taskQueue = options.taskQueue ?? workflowTaskQueue
        self.doNotEagerlyExecute = options.disableEagerActivityExecution
        self.arguments = input.map { .init(temporalPayload: $0) }
        self.cancellationType = .init(cancellationType: options.cancellationType)
        self.versioningIntent = .init(versioningIntent: options.versioningIntent)

        if let heartbeatTimeout = options.heartbeatTimeout {
            self.heartbeatTimeout = .init(duration: heartbeatTimeout)
        }
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
    }
}
