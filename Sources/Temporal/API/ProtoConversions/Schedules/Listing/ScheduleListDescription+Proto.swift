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

extension ScheduleListDescription {
    init(proto: Api.Schedule.V1.ScheduleListEntry) {
        self.id = proto.scheduleID
        self.info = .init(proto: proto.info)
        self.schedule = .init(proto: proto.info)
        // TODO: Memo
    }
}
