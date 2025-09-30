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

/// Interval-based timing specification for regular, periodic schedule execution.
public struct ScheduleIntervalSpecification: Hashable, Sendable {
    /// The duration between each scheduled action execution.
    public var every: Duration

    /// An optional fixed offset added to each calculated interval time.
    public var offset: Duration?

    /// Creates a fixed-interval schedule specification with optional timing offset.
    ///
    /// - Parameters:
    ///   - every: The duration between each scheduled execution.
    ///   - offset: Optional fixed offset to apply to all calculated times.
    public init(every: Duration, offset: Duration? = nil) {
        self.every = every
        self.offset = offset
    }
}
