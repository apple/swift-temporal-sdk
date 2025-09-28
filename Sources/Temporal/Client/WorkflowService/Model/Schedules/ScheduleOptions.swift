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

import struct GRPCCore.CallOptions

/// Configuration options for schedule creation and initial behavior.
public struct ScheduleOptions: Sendable {
    /// Controls whether the schedule triggers an immediate action upon creation.
    public var triggerImmediately: Bool

    /// Initial backfill operations to execute when the schedule is created.
    public var backfills: [ScheduleBackfill]

    /// Optional memo data to attach to the schedule for organizational purposes.
    public var memo: [String: any Sendable]?

    /// Optional search attributes to enable schedule querying and filtering.
    public var searchAttributes: SearchAttributeCollection?

    /// Options for the underlying gRPC call.
    ///
    /// If nil, the SDK applies default metadata headers and retry policies.
    public var callOptions: CallOptions?

    /// Creates schedule creation options with specified initial behavior and metadata.
    /// - Parameters:
    ///   - triggerImmediately: Whether to execute the action immediately upon schedule creation.
    ///   - backfills: Initial backfill operations to process historical time periods.
    ///   - memo: Optional memo data for organizational purposes.
    ///   - searchAttributes: Optional search attributes for querying capabilities.
    ///   - callOptions: Options for the underlying gRPC call.
    public init(
        triggerImmediately: Bool = false,
        backfills: [ScheduleBackfill] = [],
        memo: [String: any Sendable]? = nil,
        searchAttributes: SearchAttributeCollection? = nil,
        callOptions: CallOptions? = nil
    ) {
        self.triggerImmediately = triggerImmediately
        self.backfills = backfills
        self.memo = memo
        self.searchAttributes = searchAttributes
        self.callOptions = callOptions
    }
}
