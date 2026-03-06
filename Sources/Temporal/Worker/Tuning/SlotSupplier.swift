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

/// Determines how slots are allocated for workflow, activity, or local activity task processing.
///
/// Each slot represents one concurrent task execution. The slot supplier controls
/// how many tasks can run in parallel and how that number is determined.
public struct SlotSupplier: Sendable {
    package enum Kind: Sendable {
        case fixedSize(FixedSizeSlotSupplierOptions)
        case resourceBased(options: ResourceBasedSlotSupplierOptions, tunerOptions: ResourceBasedTunerOptions)
    }

    package let kind: Kind

    private init(_ kind: Kind) {
        self.kind = kind
    }

    /// Fixed number of slots available for task processing.
    ///
    /// The worker will never execute more than the supplier's ``FixedSizeSlotSupplierOptions/maximumSlots``
    /// tasks of this type concurrently.
    ///
    /// - Parameter options: The fixed-size slot supplier configuration.
    /// - Returns: A slot supplier with fixed concurrency.
    public static func fixedSize(_ options: FixedSizeSlotSupplierOptions) -> SlotSupplier {
        .init(.fixedSize(options))
    }

    /// Dynamically adjusts the number of slots based on system resource usage.
    ///
    /// The worker monitors CPU and memory usage and scales the number of available slots
    /// up or down to stay within the configured resource targets.
    ///
    /// - Parameters:
    ///   - options: Per-supplier slot configuration (min/max slots, ramp throttle).
    ///   - tunerOptions: System-wide resource targets (memory, CPU) shared across all resource-based suppliers.
    /// - Returns: A slot supplier with resource-based concurrency.
    public static func resourceBased(
        _ options: ResourceBasedSlotSupplierOptions = .init(),
        tunerOptions: ResourceBasedTunerOptions
    ) -> SlotSupplier {
        .init(.resourceBased(options: options, tunerOptions: tunerOptions))
    }
}
