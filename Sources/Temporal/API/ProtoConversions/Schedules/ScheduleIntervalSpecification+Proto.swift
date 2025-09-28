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

extension Temporal_Api_Schedule_V1_IntervalSpec {
    init(intervalSpecification: ScheduleIntervalSpecification) {
        self.interval = .init(duration: intervalSpecification.every)
        if let offset = intervalSpecification.offset {
            self.phase = .init(duration: offset)
        }
    }
}

extension ScheduleIntervalSpecification {
    init(proto: Temporal_Api_Schedule_V1_IntervalSpec) {
        self.every = .init(proto.interval)
        self.offset = proto.hasPhase ? .init(proto.phase) : nil
    }
}
