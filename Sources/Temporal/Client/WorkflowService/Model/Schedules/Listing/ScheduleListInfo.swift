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

/// Provides runtime information about a schedule returned in listing operations.
public struct ScheduleListInfo: Hashable, Sendable {
    /// The most recent schedule action results, ordered from oldest to newest.
    public var recentActions: [ScheduleInfo.ActionResult]

    /// The upcoming scheduled action execution times.
    public var nextActionTimes: [Date]

    /// Creates new information about a listed schedule.
    ///
    /// - Parameters:
    ///   - recentActions: The most recent action results, oldest first.
    ///   - nextActionTimes: The next scheduled action execution times.
    package init(recentActions: [ScheduleInfo.ActionResult] = [], nextActionTimes: [Date] = []) {
        self.recentActions = recentActions
        self.nextActionTimes = nextActionTimes
    }
}
