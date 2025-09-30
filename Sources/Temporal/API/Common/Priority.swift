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

/// Priority contains metadata that controls relative ordering of task processing when tasks are backlogged in a queue.
///
/// Initially, Priority will be used in activity and workflow task queues, which are typically where backlogs exist.
/// Other queues in the server (such as transfer and timer queues) and rate limiting decisions do not use Priority, but may in the future.
///
/// Priority is attached to workflows and activities. Activities and child
/// workflows inherit Priority from the workflow that created them, but may
/// override fields when they are started or modified. For each field of a
/// Priority on an activity/workflow, not present or equal to zero/empty string
/// means to inherit the value from the calling workflow, or if there is no
/// calling workflow, then use the default (documented below).
///
/// Despite being named "Priority", this message will also contains fields that
/// control "fairness" mechanisms.
///
/// The overall semantics of Priority are:
/// 1. First, consider "priority_key": lower number goes first.
/// (more will be added here later)
public struct Priority: Hashable, Sendable {
    /// Priority key is a positive integer from 1 to n, where smaller integers correspond to higher priorities (tasks run sooner).
    ///
    /// In general, tasks in a queue should be processed in close to priority order, although small deviations are possible.
    ///
    /// The maximum priority value (minimum priority) is determined by server
    /// configuration, and defaults to 5.
    ///
    /// The default priority is (min+max)/2. With the default max of 5 and min of
    /// 1, that comes out to 3.
    public var key: Int
}
