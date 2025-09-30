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

/// Represents the complete configuration details of a schedule in listing operations.
public struct ScheduleListEntry: Hashable, Sendable {
    /// The action that will be executed when the schedule triggers.
    public var action: ScheduleListAction

    /// The timing specification that determines when the action is executed.
    public var spec: ScheduleSpecification

    /// The current operational state of the schedule.
    public var state: ScheduleListState
}
