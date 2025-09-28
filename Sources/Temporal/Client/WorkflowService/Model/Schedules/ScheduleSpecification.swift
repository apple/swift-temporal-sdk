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

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// Timing specification that defines when scheduled actions should occur.
///
/// The scheduled times are defined as the union of ``calendars`` and ``intervals``
/// excluding any time ranges defined in ``skip``.
public struct ScheduleSpecification: Hashable, Sendable {
    /// Calendar-based timing rules that define complex scheduling patterns.
    public var calendars: [ScheduleCalendarSpecification] = []

    /// Interval-based timing rules for regular, periodic execution.
    ///
    /// Matches times expressed as `epoch + n * every + offset`.
    public var intervals: [ScheduleIntervalSpecification] = []

    // Storage of `cronExpressions`, required for the proto mapping logic not throwing deprecation warnings
    package var _cronExpressions: [String] = []

    /// Cron-based specification of times.
    ///
    /// This is provided for easy migration from legacy string-based cron scheduling.
    /// These expressions will be translated to calendar-based specifications on the server.
    @available(*, deprecated, message: "Provided for legacy cron support. Use the structured `calendars` property instead.")
    public var cronExpressions: [String] {
        get { self._cronExpressions }
        set { self._cronExpressions = newValue }
    }

    /// Calendar-based rules for explicitly excluding times from the schedule.
    public var skip: [ScheduleCalendarSpecification] = []

    /// The absolute earliest time when scheduled actions can occur.
    public var startAt: Date?

    /// The absolute latest time when scheduled actions can occur.
    public var endAt: Date?

    /// Optional random timing variation applied to each scheduled action.
    ///
    /// An action's scheduled time will be incremented by a random value between `0` and this value
    /// if present (but not past the next schedule).
    public var jitter: Duration?

    /// The IANA timezone name for interpreting calendar-based scheduling rules.
    public var timeZoneName: String?

    /// Creates a new `ScheduleSpecification`.
    ///
    /// - Note: Specifying ``cronExpressions`` is deprecated, please use ``init(calendars:intervals:skip:startAt:endAt:jitter:timeZoneName:)`` to create a new ``ScheduleSpecification``.
    ///
    /// - Parameters:
    ///   - calendars: Calendar-based rules.
    ///   - intervals: Interval-based rules.
    ///   - cronExpressions: Cron strings for compatibility.
    ///   - skip: Calendar-based skip rules.
    ///   - startAt: Earliest allowed schedule time.
    ///   - endAt: Latest allowed schedule time.
    ///   - jitter: Max random offset for scheduled times.
    ///   - timeZoneName: Time zone name (IANA format).
    @available(*, deprecated)
    public init(
        calendars: [ScheduleCalendarSpecification] = [],
        intervals: [ScheduleIntervalSpecification] = [],
        cronExpressions: [String] = [],
        skip: [ScheduleCalendarSpecification] = [],
        startAt: Date? = nil,
        endAt: Date? = nil,
        jitter: Duration? = nil,
        timeZoneName: String? = nil
    ) {
        self.calendars = calendars
        self.intervals = intervals
        self.cronExpressions = cronExpressions
        self.skip = skip
        self.startAt = startAt
        self.endAt = endAt
        self.jitter = jitter
        self.timeZoneName = timeZoneName
    }

    /// Creates a comprehensive schedule specification using structured timing rules.
    ///
    /// - Parameters:
    ///   - calendars: Calendar-based timing patterns.
    ///   - intervals: Interval-based timing patterns.
    ///   - skip: Calendar patterns to exclude from scheduling.
    ///   - startAt: Earliest allowed execution time.
    ///   - endAt: Latest allowed execution time.
    ///   - jitter: Maximum random timing variation.
    ///   - timeZoneName: IANA timezone name for calendar interpretation.
    public init(
        calendars: [ScheduleCalendarSpecification] = [],
        intervals: [ScheduleIntervalSpecification] = [],
        skip: [ScheduleCalendarSpecification] = [],
        startAt: Date? = nil,
        endAt: Date? = nil,
        jitter: Duration? = nil,
        timeZoneName: String? = nil
    ) {
        self.calendars = calendars
        self.intervals = intervals
        self.skip = skip
        self.startAt = startAt
        self.endAt = endAt
        self.jitter = jitter
        self.timeZoneName = timeZoneName
    }
}
