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

extension Temporal_Api_Schedule_V1_StructuredCalendarSpec {
    init(calendarSpecification: ScheduleCalendarSpecification) {
        self.second = .init(ranges: calendarSpecification.second)
        self.minute = .init(ranges: calendarSpecification.minute)
        self.hour = .init(ranges: calendarSpecification.hour)
        self.month = .init(ranges: calendarSpecification.month)
        self.year = .init(ranges: calendarSpecification.year)
        self.dayOfMonth = .init(ranges: calendarSpecification.dayOfMonth)
        self.dayOfWeek = .init(ranges: calendarSpecification.dayOfWeek)
        if let comment = calendarSpecification.comment {
            self.comment = comment
        }
    }
}

extension ScheduleCalendarSpecification {
    init(proto: Temporal_Api_Schedule_V1_StructuredCalendarSpec) {
        self.second = .init(protos: proto.second)
        self.minute = .init(protos: proto.minute)
        self.hour = .init(protos: proto.hour)
        self.month = .init(protos: proto.month)
        self.year = .init(protos: proto.year)
        self.dayOfMonth = .init(protos: proto.dayOfMonth)
        self.dayOfWeek = .init(protos: proto.dayOfWeek)
        self.comment = proto.comment.isEmpty ? nil : self.comment
    }
}
