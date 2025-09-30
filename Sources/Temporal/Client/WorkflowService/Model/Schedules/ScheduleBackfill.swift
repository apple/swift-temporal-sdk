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

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// Configuration for executing schedule actions across historical time periods.
public struct ScheduleBackfill: Hashable, Sendable {
    /// The exclusive start boundary of the backfill time range.
    public var startAt: Date

    /// The inclusive end boundary of the backfill time range.
    public var endAt: Date

    /// Optional overlap policy override for this specific backfill operation.
    public var overlap: ScheduleOverlapPolicy?

    /// Creates a backfill configuration for processing historical schedule periods.
    ///
    /// - Parameters:
    ///   - startAt: The exclusive start time for backfill evaluation.
    ///   - endAt: The inclusive end time for backfill evaluation.
    ///   - overlap: Optional overlap policy override for this backfill operation.
    public init(startAt: Date, endAt: Date, overlap: ScheduleOverlapPolicy? = nil) {
        self.startAt = startAt
        self.endAt = endAt
        self.overlap = overlap
    }
}
