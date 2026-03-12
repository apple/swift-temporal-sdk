//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Temporal SDK open source project
//
// Copyright (c) 2026 Apple Inc. and the Swift Temporal SDK project authors
// Licensed under MIT License
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Swift Temporal SDK project authors
//
// SPDX-License-Identifier: MIT
//
//===----------------------------------------------------------------------===//

/// Priority contains metadata that controls relative ordering of task processing when tasks are
/// backlogged in a queue.
///
/// Priority is used in activity and workflow task queues, which are typically where backlogs exist.
/// Priority is attached to workflows and activities. Activities and child workflows inherit priority
/// from the workflow that created them, but may override individual fields when they are started or
/// modified.
///
/// For each field, a value of `nil` (or zero/empty string at the proto level) means to inherit the
/// value from the calling workflow, or if there is no calling workflow, use the default value
/// documented on the field.
///
/// The overall semantics of priority are:
/// 1. First, consider ``priorityKey``: lower numbers go first (higher priority).
/// 2. Then, consider fairness: the fairness mechanism attempts to dispatch tasks for a given
///    ``fairnessKey`` in proportion to its ``fairnessWeight``.
public struct Priority: Sendable {
    /// The priority key, which is a positive integer from 1 to *n*, where smaller integers
    /// correspond to higher priorities (tasks run sooner).
    ///
    /// In general, tasks in a queue are processed in close to priority order, although small
    /// deviations are possible. The maximum priority value (minimum priority) is determined by
    /// server configuration and defaults to 5.
    ///
    /// The default priority is `(min + max) / 2`. With the default max of 5 and min of 1, that
    /// comes out to 3.
    ///
    /// A value of `nil` means inherit from the calling workflow or use the server default.
    public var priorityKey: Int?

    /// A short string used as a key for the fairness balancing mechanism.
    ///
    /// It may correspond to a tenant ID, or to a fixed string like `"high"` or `"low"`. The
    /// default is the empty string.
    ///
    /// The fairness mechanism attempts to dispatch tasks for a given key in proportion to its
    /// weight. For example, using a thousand distinct tenant IDs, each with a weight of 1.0 (the
    /// default), will result in each tenant getting a roughly equal share of task dispatch
    /// throughput.
    ///
    /// Fairness keys are limited to 64 bytes.
    ///
    /// A value of `nil` means inherit from the calling workflow (defaults to empty string).
    public var fairnessKey: String?

    /// The fairness weight, which can come from multiple sources for flexibility.
    ///
    /// From highest to lowest precedence:
    /// 1. Weights for a small set of keys can be overridden in task queue configuration with an API.
    /// 2. It can be attached to the workflow or activity in this field.
    /// 3. The default weight of 1.0 will be used.
    ///
    /// Weight values are clamped to the range \[0.001, 1000\].
    ///
    /// A value of `nil` means inherit from the calling workflow or use the default weight of 1.0.
    public var fairnessWeight: Float?

    /// Creates a priority configuration.
    ///
    /// - Parameters:
    ///   - priorityKey: The priority key (1 to *n*, lower = higher priority). `nil` means inherit.
    ///   - fairnessKey: Short string used as a key for fairness balancing. `nil` means inherit.
    ///   - fairnessWeight: Weight for fairness balancing, clamped to \[0.001, 1000\]. `nil` means
    ///     inherit.
    public init(priorityKey: Int? = nil, fairnessKey: String? = nil, fairnessWeight: Float? = nil) {
        self.priorityKey = priorityKey
        self.fairnessKey = fairnessKey
        self.fairnessWeight = fairnessWeight
    }

    /// The default priority (all fields `nil` = inherit/use server defaults).
    public static let `default` = Priority()
}
