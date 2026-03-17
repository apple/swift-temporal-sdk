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

/// Details about why an activity was cancelled, paused, or reset.
public struct ActivityCancellationDetails: Sendable, Hashable {
    /// Whether the activity was explicitly cancelled.
    public var cancelRequested: Bool

    /// Whether the activity was explicitly paused.
    public var paused: Bool

    /// Whether the activity was explicitly reset.
    public var reset: Bool

    /// Creates cancellation details.
    ///
    /// - Parameters:
    ///   - cancelRequested: Whether the activity was explicitly cancelled.
    ///   - paused: Whether the activity was explicitly paused.
    ///   - reset: Whether the activity was explicitly reset.
    public init(cancelRequested: Bool, paused: Bool, reset: Bool) {
        self.cancelRequested = cancelRequested
        self.paused = paused
        self.reset = reset
    }
}
