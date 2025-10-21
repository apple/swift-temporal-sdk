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

extension ScheduleListInfo {
    init(proto: Temporal_Api_Schedule_V1_ScheduleListInfo) {
        self.recentActions = proto.recentActions.map { .init(proto: $0) }
        self.nextActionTimes = proto.futureActionTimes.map { $0.date }
    }
}
