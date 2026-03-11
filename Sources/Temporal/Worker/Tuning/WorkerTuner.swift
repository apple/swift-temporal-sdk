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

/// Controls how task processing slots are allocated across workflow, activity, and local activity workers.
///
/// A ``WorkerTuner`` groups together separate ``SlotSupplier`` instances for each task type,
/// allowing fine-grained control over concurrency. You can mix different supplier strategies --
/// for example, using a fixed-size supplier for workflows and a resource-based supplier for activities.
///
/// ## Fixed-size tuner
///
/// Use fixed slot counts for predictable concurrency limits:
///
/// ```swift
/// let tuner = WorkerTuner(
///     workflowSlotSupplier: .fixedSize(.init(maximumSlots: 100)),
///     activitySlotSupplier: .fixedSize(.init(maximumSlots: 200)),
///     localActivitySlotSupplier: .fixedSize(.init(maximumSlots: 100))
/// )
/// ```
///
/// ## Resource-based tuner
///
/// Use the ``resourceBased(targetMemoryUsage:targetCpuUsage:workflowOptions:activityOptions:localActivityOptions:)``
/// factory to create a tuner that dynamically scales all slot types based on system resource usage:
///
/// ```swift
/// let tuner = WorkerTuner.resourceBased(
///     targetMemoryUsage: 0.8,
///     targetCpuUsage: 0.9,
///     workflowOptions: .init(minimumSlots: 2, maximumSlots: 50),
///     activityOptions: .init(minimumSlots: 10, maximumSlots: 200)
/// )
/// ```
///
/// ## Applying a tuner
///
/// Set the tuner on the worker configuration:
///
/// ```swift
/// var config = TemporalWorker.Configuration(...)
/// config.tuner = tuner
/// ```
public struct WorkerTuner: Sendable {
    /// Slot supplier for workflow task processing.
    public var workflowSlotSupplier: SlotSupplier

    /// Slot supplier for activity task processing.
    public var activitySlotSupplier: SlotSupplier

    /// Slot supplier for local activity task processing.
    public var localActivitySlotSupplier: SlotSupplier

    /// Creates a worker tuner with the specified slot suppliers.
    ///
    /// - Parameters:
    ///   - workflowSlotSupplier: Slot supplier for workflow tasks. Defaults to fixed-size with 100 slots.
    ///   - activitySlotSupplier: Slot supplier for activity tasks. Defaults to fixed-size with 100 slots.
    ///   - localActivitySlotSupplier: Slot supplier for local activity tasks. Defaults to fixed-size with 100 slots.
    public init(
        workflowSlotSupplier: SlotSupplier = .fixedSize(.init()),
        activitySlotSupplier: SlotSupplier = .fixedSize(.init()),
        localActivitySlotSupplier: SlotSupplier = .fixedSize(.init())
    ) {
        self.workflowSlotSupplier = workflowSlotSupplier
        self.activitySlotSupplier = activitySlotSupplier
        self.localActivitySlotSupplier = localActivitySlotSupplier
    }

    /// Creates a resource-based tuner that dynamically scales all slot types based on
    /// system CPU and memory usage.
    ///
    /// All three slot suppliers (workflow, activity, and local activity) share the same
    /// resource targets but can have individual slot configuration options.
    ///
    /// - Parameters:
    ///   - targetMemoryUsage: Target system memory usage as a fraction (0.0--1.0). Defaults to `0.8`.
    ///   - targetCpuUsage: Target system CPU usage as a fraction (0.0--1.0). Defaults to `0.9`.
    ///   - workflowOptions: Per-supplier slot options for workflow tasks. Defaults to standard options.
    ///   - activityOptions: Per-supplier slot options for activity tasks. Defaults to standard options.
    ///   - localActivityOptions: Per-supplier slot options for local activity tasks. Defaults to standard options.
    /// - Returns: A tuner with resource-based slot suppliers for all task types.
    public static func resourceBased(
        targetMemoryUsage: Double = 0.8,
        targetCpuUsage: Double = 0.9,
        workflowOptions: ResourceBasedSlotSupplierOptions = .init(),
        activityOptions: ResourceBasedSlotSupplierOptions = .init(),
        localActivityOptions: ResourceBasedSlotSupplierOptions = .init()
    ) -> WorkerTuner {
        let tunerOptions = ResourceBasedTunerOptions(
            targetMemoryUsage: targetMemoryUsage,
            targetCpuUsage: targetCpuUsage
        )
        return WorkerTuner(
            workflowSlotSupplier: .resourceBased(workflowOptions, tunerOptions: tunerOptions),
            activitySlotSupplier: .resourceBased(activityOptions, tunerOptions: tunerOptions),
            localActivitySlotSupplier: .resourceBased(localActivityOptions, tunerOptions: tunerOptions)
        )
    }
}
