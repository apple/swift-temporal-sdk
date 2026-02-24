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

extension Api.Workflowservice.V1.CreateScheduleRequest {
    init<Input>(
        namespace: String,
        identity: String,
        requestID: String,
        scheduleID: String,
        schedule: Schedule<Input>,
        scheduleOptions: ScheduleOptions?,
        dataConverter: DataConverter
    ) async throws {
        self = .with {
            $0.namespace = namespace
            $0.identity = identity
            $0.requestID = requestID
            $0.scheduleID = scheduleID
        }

        let scheduleProto: Api.Schedule.V1.Schedule = try await .init(schedule: schedule, dataConverter: dataConverter)

        self.schedule = .with {
            $0 = scheduleProto
        }

        if let memo = scheduleOptions?.memo {
            var temporalPayloads = [String: Api.Common.V1.Payload]()
            for (key, value) in memo {
                temporalPayloads[key] = try await dataConverter.convertValue(value)
            }
            self.memo = .with {
                $0.fields = temporalPayloads
            }
        }

        if let searchAttributes = scheduleOptions?.searchAttributes {
            self.searchAttributes = .init(searchAttributes)
        }

        self.initialPatch = .with {
            if let triggerImmediately = scheduleOptions?.triggerImmediately, triggerImmediately {
                $0.triggerImmediately.overlapPolicy = .init(overlapPolicy: schedule.policy.overlap)
            }

            if let backfills = scheduleOptions?.backfills {
                $0.backfillRequest = backfills.map { .init(scheduleBackfill: $0) }
            }
        }
    }
}
