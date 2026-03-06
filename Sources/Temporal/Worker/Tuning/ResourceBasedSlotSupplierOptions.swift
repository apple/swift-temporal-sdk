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

/// Per-supplier options for a resource-based slot supplier.
///
/// These options control the slot allocation behavior of an individual resource-based slot
/// supplier. Each supplier can have different slot limits and ramp throttle settings, while
/// sharing the same ``ResourceBasedTunerOptions`` for system resource targets.
public struct ResourceBasedSlotSupplierOptions: Sendable {
    /// Minimum number of slots that will be issued regardless of resource usage.
    ///
    /// The supplier will always maintain at least this many slots, even if resource
    /// usage is above the target thresholds.
    public var minimumSlots: Int

    /// Maximum number of slots that can ever be issued.
    ///
    /// The supplier will never allocate more than this many slots, even if resource
    /// usage is well below the target thresholds.
    public var maximumSlots: Int

    /// Minimum time to wait between issuing new slots after the minimum has been reached.
    ///
    /// This throttle exists because the resource impact of a task cannot be determined
    /// ahead of time. The system waits to observe resource usage before issuing additional
    /// slots.
    public var rampThrottle: Duration

    /// Creates per-supplier options for a resource-based slot supplier.
    ///
    /// - Parameters:
    ///   - minimumSlots: Minimum number of slots that will always be available. Defaults to `5`.
    ///   - maximumSlots: Maximum number of slots that can be issued. Defaults to `100`.
    ///   - rampThrottle: Minimum time between issuing new slots after reaching the minimum. Defaults to 50 milliseconds.
    public init(
        minimumSlots: Int = 5,
        maximumSlots: Int = 100,
        rampThrottle: Duration = .milliseconds(50)
    ) {
        self.minimumSlots = minimumSlots
        self.maximumSlots = maximumSlots
        self.rampThrottle = rampThrottle
    }
}
