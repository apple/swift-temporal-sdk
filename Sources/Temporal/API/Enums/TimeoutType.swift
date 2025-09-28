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

/// The type of a Temporal timeout.
///
/// See also: [https://temporal.io/blog/activity-timeouts](https://temporal.io/blog/activity-timeouts)
public enum TimeoutType: Hashable, Sendable {
    case unspecified
    case startToClose
    case scheduleToStart
    case scheduleToClose
    case heartbeat
}
