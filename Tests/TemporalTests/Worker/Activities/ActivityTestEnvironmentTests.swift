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

import Temporal
import TemporalTestKit
import Testing

@Suite
struct ActivityTestEnvironmentTests {
    @Test
    func activityInfo() async throws {
        let info = try await ActivityExecutionContext.Info(
            heartbeatDetails: "Hello World"
        )

        try await withActivityTestEnvironment(info: info, cancellationReason: .serverRequest) {
            let context = try #require(ActivityExecutionContext.current)

            #expect(context.info.activityID == info.activityID)
            #expect(context.info.activityType == info.activityType)
            #expect(context.info.attempt == info.attempt)
            #expect(context.info.isLocal == info.isLocal)
            #expect(context.info.scheduleToCloseTimeout == info.scheduleToCloseTimeout)
            #expect(context.info.startToCloseTimeout == info.startToCloseTimeout)
            #expect(context.info.heartbeatTimeout == info.heartbeatTimeout)
            #expect(context.info.scheduledTime == info.scheduledTime)
            #expect(context.info.currentAttemptScheduled == info.currentAttemptScheduled)
            #expect(context.info.startedTime == info.startedTime)
            #expect(context.info.taskQueue == info.taskQueue)
            #expect(context.info.taskToken == info.taskToken)
            #expect(context.info.workflowID == info.workflowID)
            #expect(context.info.workflowNamespace == info.workflowNamespace)
            #expect(context.info.workflowRunID == info.workflowRunID)
            #expect(context.info.workflowType == info.workflowType)

            let details = try await context.info.heartbeatDetails(as: String.self)
            #expect(details == "Hello World")

            switch context.cancellationReason {
            case .serverRequest:
                break
            default:
                Issue.record("Unexpected cancellation reason: \(context.cancellationReason)")
            }
        }
    }

    @Test
    func emitHeartbeatDetails() async throws {
        let info = try await ActivityExecutionContext.Info()

        try await withActivityTestEnvironment(info: info) {
            let context = try #require(ActivityExecutionContext.current)

            context.heartbeat(details: "Heartbeat 1")
            context.heartbeat(details: "Heartbeat 2")
            context.heartbeat(details: "Heartbeat 3")
            context.heartbeat(details: "Heartbeat 4")
        } assertHeartbeatDetails: { heartbeats in
            var recordedDetails: [String] = []
            for try await details in heartbeats {
                guard let stringDetails = details as? [String] else {
                    Issue.record("Unexpected heartbeat details type of \(details)")
                    continue
                }
                recordedDetails.append(contentsOf: stringDetails)
            }

            #expect(
                recordedDetails == [
                    "Heartbeat 1",
                    "Heartbeat 2",
                    "Heartbeat 3",
                    "Heartbeat 4",
                ]
            )
        }
    }
}
