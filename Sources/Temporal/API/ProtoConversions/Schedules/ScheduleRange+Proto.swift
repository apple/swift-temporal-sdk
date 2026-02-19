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

extension Api.Schedule.V1.Range {
    init(range: ScheduleRange) {
        self = .init()
        self.start = Int32(range.start)
        self.end = Int32(range.end)
        self.step = Int32(range.step)
    }
}

extension Array where Element == Api.Schedule.V1.Range {
    init(ranges: [ScheduleRange]) {
        self = ranges.map { .init(range: $0) }
    }
}

extension ScheduleRange {
    init(proto: Api.Schedule.V1.Range) {
        self.start = Int(proto.start)
        self.end = Int(proto.end)
        self.step = Int(proto.step)
    }
}

extension Array where Element == ScheduleRange {
    init(protos: [Api.Schedule.V1.Range]) {
        self = protos.map(ScheduleRange.init)
    }
}
