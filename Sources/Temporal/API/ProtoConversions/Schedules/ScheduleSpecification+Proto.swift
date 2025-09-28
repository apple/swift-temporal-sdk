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

import SwiftProtobuf

extension Temporal_Api_Schedule_V1_ScheduleSpec {
    init(specification: ScheduleSpecification) {
        self.structuredCalendar = specification.calendars.map { .init(calendarSpecification: $0) }
        self.interval = specification.intervals.map { .init(intervalSpecification: $0) }
        self.cronString = specification._cronExpressions
        self.excludeStructuredCalendar = specification.skip.map { .init(calendarSpecification: $0) }
        if let startAt = specification.startAt {
            self.startTime = .init(date: startAt)
        }
        if let endAt = specification.endAt {
            self.endTime = .init(date: endAt)
        }
        if let jitter = specification.jitter {
            self.jitter = .init(rounding: jitter)
        }
        if let timeZoneName = specification.timeZoneName {
            self.timezoneName = timeZoneName
        }
    }
}

extension ScheduleSpecification {
    init(proto: Temporal_Api_Schedule_V1_ScheduleSpec) {
        self.calendars = proto.structuredCalendar.map { .init(proto: $0) }
        self.intervals = proto.interval.map { .init(proto: $0) }
        self._cronExpressions = proto.cronString
        self.skip = proto.excludeStructuredCalendar.map { .init(proto: $0) }
        self.startAt = proto.hasStartTime ? proto.startTime.date : nil
        self.endAt = proto.hasEndTime ? proto.endTime.date : nil
        self.jitter = proto.hasJitter ? .init(proto.jitter) : nil
        self.timeZoneName = proto.timezoneName.isEmpty ? nil : proto.timezoneName
    }
}
