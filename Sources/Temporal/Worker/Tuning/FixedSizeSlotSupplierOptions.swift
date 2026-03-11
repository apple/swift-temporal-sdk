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

/// Per-supplier options for a fixed slot supplier.
///
/// The worker will never execute more than ``maximumSlots`` tasks of this type
/// concurrently. The slot count does not change during the worker's lifetime.
public struct FixedSizeSlotSupplierOptions: Sendable {
    /// The maximum number of concurrent task executions.
    public var maximumSlots: Int

    /// Creates a fixed-size slot supplier.
    ///
    /// - Parameter maximumSlots: The maximum number of concurrent task executions. Defaults to `100`.
    public init(maximumSlots: Int = 100) {
        self.maximumSlots = maximumSlots
    }
}
