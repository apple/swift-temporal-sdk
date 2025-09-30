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

extension Temporal_Api_Schedule_V1_BackfillRequest {
    init(scheduleBackfill: ScheduleBackfill) {
        self.startTime = .init(date: scheduleBackfill.startAt)
        self.endTime = .init(date: scheduleBackfill.endAt)
        if let overlap = scheduleBackfill.overlap {
            self.overlapPolicy = .init(overlapPolicy: overlap)
        }
    }
}
