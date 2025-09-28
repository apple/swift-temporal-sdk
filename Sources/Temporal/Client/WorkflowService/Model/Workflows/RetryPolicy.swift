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

/// Configuration for automatic retry behavior when operations fail.
public struct RetryPolicy: Hashable, Sendable {
    /// The time delay before the first retry attempt.
    ///
    /// This duration specifies how long to wait after an initial failure before making the first
    /// retry attempt. If the ``backoffCoefficient`` is 1.0, this interval is used for all retries.
    /// If `nil`, a default interval will be used by the Temporal server.
    public var initialInterval: Duration?

    /// The multiplier for calculating exponential backoff between retry attempts.
    ///
    /// Each retry interval is calculated by multiplying the previous interval by this coefficient.
    /// For example, with an initial interval of 1 second and a coefficient of 2.0, subsequent
    /// retries will occur after 1s, 2s, 4s, 8s, etc. Must be 1.0 or greater. A value of 1.0
    /// results in fixed intervals with no exponential growth.
    public var backoffCoefficient: Double

    /// The maximum time duration to wait between retry attempts.
    ///
    /// Exponential backoff can lead to very long intervals between retries. This value caps
    /// the maximum interval to prevent excessive delays. If not specified, defaults to
    /// 100 times the initial interval. This prevents runaway exponential growth in retry delays.
    public var maximumInterval: Duration?

    /// The maximum number of retry attempts allowed.
    ///
    /// When this limit is reached, retries stop even if other timeout constraints haven't been met.
    /// Special values:
    /// - `0`: Unlimited retries (subject to other timeout constraints)
    /// - `1`: No retries (fail immediately after first attempt)
    /// - `> 1`: Retry up to this many times total (including the initial attempt)
    public var maximumAttempts: Int = 0

    /// Error types that will prevent further retries.
    ///
    /// This list specifies fully qualified error type names that are considered non-retryable by the Temporal server.
    /// If a workflow or activity fails with an error whose type exactly matches one of the entries in this list,
    /// the retry policy will be bypassed and the failure will be returned immediately to the caller or propagated
    /// to the workflow.
    ///
    /// Matching is done against the application error ``ApplicationError/type`` field (nested within the
    /// respective ``TemporalError/cause``), which must match the string **exactly**.
    /// This check is case-sensitive and does not support wildcards or substring matches.
    ///
    /// - Note: If this list is empty, all non-terminal failures are considered retryable unless constrained by
    ///   other retry policy parameters such as ``maximumAttempts`` or ``maximumInterval``.
    public var nonRetryableErrorTypes: [String] = []

    /// Creates a retry policy with the specified configuration.
    ///
    /// - Parameters:
    ///   - initialInterval: The delay before the first retry. Defaults to `nil` (server default).
    ///   - backoffCoefficient: The exponential backoff multiplier. Defaults to 0 (server default).
    ///   - maximumInterval: The maximum retry interval cap. Defaults to `nil` (100x initial interval).
    ///   - maximumAttempts: The maximum number of retry attempts. Defaults to 0 (unlimited).
    ///   - nonRetryableErrorTypes: Error types that will prevent further retries. Defaults to none (unlimited).
    public init(
        initialInterval: Duration? = nil,
        backoffCoefficient: Double = 0,
        maximumInterval: Duration? = nil,
        maximumAttempts: Int = 0,
        nonRetryableErrorTypes: [String] = []
    ) {
        self.initialInterval = initialInterval
        self.backoffCoefficient = backoffCoefficient
        self.maximumInterval = maximumInterval
        self.maximumAttempts = maximumAttempts
        self.nonRetryableErrorTypes = nonRetryableErrorTypes
    }
}
