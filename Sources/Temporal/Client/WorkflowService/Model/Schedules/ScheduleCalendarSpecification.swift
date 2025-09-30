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

/// Calendar-based timing specification for precise schedule control using date and time components.
public struct ScheduleCalendarSpecification: Hashable, Sendable {
    /// Predefined range set matching zero for time precision fields.
    public static let beginning: [ScheduleRange] = [ScheduleRange(value: 0)]

    /// Predefined range set matching all possible days within a month (1-31).
    public static let allMonthDays: [ScheduleRange] = [ScheduleRange(start: 1, end: 31)]
    /// Predefined range set matching all months within a year (1-12).
    ///
    /// This range allows schedules to trigger during any month, providing year-round scheduling capability.
    public static let allMonths: [ScheduleRange] = [ScheduleRange(start: 1, end: 12)]

    /// Predefined range set matching all days within a week (0-6, where 0 is Sunday).
    public static let allWeekDays: [ScheduleRange] = [ScheduleRange(start: 0, end: 6)]

    /// The seconds component ranges to match (0-59).
    public var second: [ScheduleRange] = beginning

    /// The minutes component ranges to match (0-59).
    public var minute: [ScheduleRange] = beginning

    /// The hours component ranges to match (0-23).
    public var hour: [ScheduleRange] = beginning

    /// The day of month component ranges to match (1-31).
    public var dayOfMonth: [ScheduleRange] = allMonthDays

    /// The month component ranges to match (1-12).
    public var month: [ScheduleRange] = allMonths

    /// The year component ranges to match.
    public var year: [ScheduleRange] = []

    /// The day of week component ranges to match (0-6, where 0 is Sunday).
    public var dayOfWeek: [ScheduleRange] = allWeekDays

    /// Optional human-readable description of this calendar specification.
    public var comment: String? = nil

    /// Creates a comprehensive calendar-based schedule specification.
    ///
    /// - Parameters:
    ///   - second: Second ranges (0-59). Defaults to zero.
    ///   - minute: Minute ranges (0-59). Defaults to zero.
    ///   - hour: Hour ranges (0-23). Defaults to zero.
    ///   - dayOfMonth: Day of month ranges (1-31). Defaults to all days.
    ///   - month: Month ranges (1-12). Defaults to all months.
    ///   - year: Year ranges. Defaults to empty (all years).
    ///   - dayOfWeek: Weekday ranges (0-6, Sunday=0). Defaults to all days.
    ///   - comment: Optional description of the specification.
    public init(
        second: [ScheduleRange] = beginning,
        minute: [ScheduleRange] = beginning,
        hour: [ScheduleRange] = beginning,
        dayOfMonth: [ScheduleRange] = allMonthDays,
        month: [ScheduleRange] = allMonths,
        year: [ScheduleRange] = [],
        dayOfWeek: [ScheduleRange] = allWeekDays,
        comment: String? = nil
    ) {
        self.second = second
        self.minute = minute
        self.hour = hour
        self.dayOfMonth = dayOfMonth
        self.month = month
        self.year = year
        self.dayOfWeek = dayOfWeek
        self.comment = comment
    }
}
