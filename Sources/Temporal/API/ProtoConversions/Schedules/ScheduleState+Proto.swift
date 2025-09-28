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

extension Temporal_Api_Schedule_V1_ScheduleState {
    init(state: ScheduleState) {
        if let note = state.note {
            self.notes = note
        }
        self.paused = state.paused
        self.limitedActions = state.limitedActions
        self.remainingActions = Int64(state.remainingActions)
    }
}

extension ScheduleState {
    init(proto: Temporal_Api_Schedule_V1_ScheduleState) {
        self.note = proto.notes.isEmpty ? nil : String(proto.notes)
        self.paused = proto.paused
        self.limitedActions = proto.limitedActions
        self.remainingActions = Int(proto.remainingActions)
    }
}
