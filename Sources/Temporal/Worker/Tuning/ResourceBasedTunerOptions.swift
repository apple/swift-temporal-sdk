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

/// Options for target system resource usage, shared across all resource-based slot suppliers.
///
/// These options control the system-wide resource targets that all resource-based slot suppliers
/// in a ``WorkerTuner`` share. Each supplier individually scales its slot count to keep the
/// system within these target thresholds.
///
/// - Important: It is not recommended to set ``targetMemoryUsage`` higher than 0.8,
///   since how much memory a task may use is not predictable and you want to avoid
///   out-of-memory errors.
public struct ResourceBasedTunerOptions: Sendable {
    /// Target system memory usage as a fraction between 0.0 and 1.0.
    ///
    /// The supplier will try to keep system memory usage at or below this level by
    /// adjusting the number of available slots.
    ///
    /// - Important: It is not recommended to set this higher than 0.8, since how much
    ///   memory a task may use is not predictable and you want to avoid out-of-memory
    ///   errors.
    public var targetMemoryUsage: Double

    /// Target system CPU usage as a fraction between 0.0 and 1.0.
    ///
    /// The supplier will try to keep system CPU usage at or below this level by
    /// adjusting the number of available slots. This can be set to 1.0 if desired,
    /// but it is recommended to leave some headroom for other processes.
    public var targetCpuUsage: Double

    /// Creates resource-based tuner options.
    ///
    /// - Parameters:
    ///   - targetMemoryUsage: Target system memory usage as a fraction (0.0--1.0). Defaults to `0.8`.
    ///   - targetCpuUsage: Target system CPU usage as a fraction (0.0--1.0). Defaults to `0.9`.
    public init(
        targetMemoryUsage: Double = 0.8,
        targetCpuUsage: Double = 0.9
    ) {
        precondition(
            0 <= targetMemoryUsage && targetMemoryUsage <= 1.0,
            "Target memory usage out of range"
        )
        precondition(
            0 <= targetCpuUsage && targetCpuUsage <= 1.0,
            "Target CPU usage out of range"
        )
        self.targetMemoryUsage = targetMemoryUsage
        self.targetCpuUsage = targetCpuUsage
    }
}
