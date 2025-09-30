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

import struct GRPCCore.CallOptions

/// Input parameters for backfilling schedule executions in client interceptors.
public struct BackfillScheduleInput: Sendable {
    /// The unique identifier of the schedule to backfill.
    public var id: String

    /// The array of time periods to backfill for the schedule.
    public var backfills: [ScheduleBackfill]

    /// Optional gRPC call options for customizing the backfill request.
    public var callOptions: CallOptions?

    /// Creates a new backfill schedule input with the specified parameters.
    ///
    /// - Parameters:
    ///   - id: The unique identifier of the schedule to backfill.
    ///   - backfills: The array of time periods to backfill for the schedule.
    ///   - callOptions: Optional gRPC call options for customizing the request.
    public init(id: String, backfills: [ScheduleBackfill], callOptions: CallOptions? = nil) {
        self.id = id
        self.backfills = backfills
        self.callOptions = callOptions
    }
}
