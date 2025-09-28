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

/// Represents the action configuration for a schedule in a schedule listing response.
public struct ScheduleListAction: Hashable, Sendable {
    /// The name of the workflow that will be started when the schedule triggers.
    public var workflow: String
}
