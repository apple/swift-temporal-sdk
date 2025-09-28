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

/// Information about a schedule's configuration and current operational state.
public struct ScheduleDescription<Input: Sendable>: Sendable {
    /// Runtime information and metrics about the schedule's operational behavior.
    public var info: ScheduleInfo

    /// The complete schedule configuration defining timing, actions, policies, and state.
    public var schedule: Schedule<Input>

    /// Optional memo data for storing custom metadata with the schedule.
    public var memo: [String: TemporalRawValue]?

    /// Optional search attributes for enabling schedule queries and filtering.
    public var searchAttributes: SearchAttributeCollection?

    /// Internal conflict detection token for safe concurrent schedule updates.
    var conflictToken: Data
}
