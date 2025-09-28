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

/// Represents an inclusive integer range with optional step intervals for schedule matching.
public struct ScheduleRange: Hashable, Sendable {
    /// The inclusive starting value of the range.
    public let start: Int

    /// The inclusive ending value of the range.
    public let end: Int

    /// The step interval between consecutive values in the range.
    public let step: Int

    /// A predefined range containing only the value zero.
    public static let zero = ScheduleRange(value: 0)

    /// Creates a range containing exactly one value.
    ///
    /// - Parameter value: The single value to include in the range. Must be non-negative.
    public init(value: Int) {
        guard value >= 0 else {
            fatalError("ScheduleRange(value:) cannot be negative.")
        }

        self.init(start: value, end: value)
    }

    /// Creates a range with specified start and end values, with optional step intervals.
    ///
    /// - Parameters:
    ///   - start: The inclusive starting value of the range.
    ///   - end: The inclusive ending value of the range.
    ///   - step: The interval between consecutive values. Must be greater than 0.
    public init(start: Int, end: Int, step: Int = 1) {
        guard start <= end else {
            fatalError("ScheduleRange(start:end:step:) must have `start` <= `end`.")
        }

        guard step > 0 else {
            fatalError("ScheduleRange(start:end:step:) must have `step` larger than 0.")
        }

        self.start = start
        self.end = end
        self.step = step
    }
}
