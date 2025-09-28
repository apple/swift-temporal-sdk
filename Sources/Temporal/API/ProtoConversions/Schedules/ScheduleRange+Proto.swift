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

extension Temporal_Api_Schedule_V1_Range {
    init(range: ScheduleRange) {
        self.start = Int32(range.start)
        self.end = Int32(range.end)
        self.step = Int32(range.step)
    }
}

extension Array where Element == Temporal_Api_Schedule_V1_Range {
    init(ranges: [ScheduleRange]) {
        self = ranges.map { .init(range: $0) }
    }
}

extension ScheduleRange {
    init(proto: Temporal_Api_Schedule_V1_Range) {
        self.start = Int(proto.start)
        self.end = Int(proto.end)
        self.step = Int(proto.step)
    }
}

extension Array where Element == ScheduleRange {
    init(protos: [Temporal_Api_Schedule_V1_Range]) {
        self = protos.map(ScheduleRange.init)
    }
}
