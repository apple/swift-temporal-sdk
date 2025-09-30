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

extension ScheduleListEntry {
    init(proto: Temporal_Api_Schedule_V1_ScheduleListInfo) {
        self.spec = .init(proto: proto.spec)
        self.state = .init(
            note: proto.notes.isEmpty ? nil : proto.notes,
            isPaused: proto.paused
        )

        guard proto.hasWorkflowType else {
            fatalError("`ScheduleAction` type not supported.")  // TODO: Improve error
        }
        self.action = .init(workflow: proto.workflowType.name)
    }
}
