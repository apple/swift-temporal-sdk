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

/// Represents the operational state of a schedule in listing operations.
public struct ScheduleListState: Hashable, Sendable {
    /// A human-readable note describing the current state of the schedule.
    public var note: String?

    /// A boolean value that indicates whether the schedule is currently paused.
    public var isPaused: Bool

    /// Creates a new schedule list state with the specified configuration.
    ///
    /// - Parameters:
    ///   - note: An optional descriptive message about the schedule state.
    ///   - isPaused: A Boolean value indicating whether the schedule is paused.
    package init(note: String? = nil, isPaused: Bool = false) {
        self.note = note
        self.isPaused = isPaused
    }
}
