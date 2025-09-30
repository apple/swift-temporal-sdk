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

/// Represents the current operational state and execution controls of a schedule.
public struct ScheduleState: Hashable, Sendable {
    /// Optional human-readable description of the schedule's current state or condition.
    public var note: String?

    /// Controls whether the schedule is currently paused and not triggering actions.
    public var paused: Bool

    /// Determines whether the schedule enforces a limit on total action executions.
    public var limitedActions: Bool

    /// The number of actions remaining before the schedule automatically stops.
    public var remainingActions: Int

    /// Creates a schedule state configuration with specified operational controls.
    ///
    /// - Parameters:
    ///   - note: Optional descriptive message about the schedule state.
    ///   - paused: Whether the schedule should start in a paused state.
    ///   - limitedActions: Whether to enforce a limit on total action executions.
    ///   - remainingActions: The maximum number of actions allowed (when limited).
    public init(
        note: String? = nil,
        paused: Bool = false,
        limitedActions: Bool = false,
        remainingActions: Int = 0
    ) {
        self.note = note
        self.paused = paused
        self.limitedActions = limitedActions
        self.remainingActions = remainingActions
    }
}
