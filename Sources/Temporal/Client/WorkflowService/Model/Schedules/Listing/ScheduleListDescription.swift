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

/// Represents a schedule entry returned in schedule listing operations.
public struct ScheduleListDescription: Sendable {
    /// The unique identifier of the schedule.
    public var id: String

    /// The schedule configuration including action, timing, and state information.
    ///
    /// - Note: This may not be present in older Temporal servers without advanced visibility.
    public var schedule: ScheduleListEntry?

    /// Runtime information about the schedule including recent actions and next execution times.
    ///
    /// - Note: This may not be present in older Temporal servers without advanced visibility.
    public var info: ScheduleListInfo?

    /// Arbitrary key-value metadata associated with the schedule.
    public var memo: [String: any Sendable]?

    // TODO: SearchAttributes
}
