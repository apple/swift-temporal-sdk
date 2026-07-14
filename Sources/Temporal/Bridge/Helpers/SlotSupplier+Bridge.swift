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

import Bridge

/// The result of converting a Swift ``SlotSupplier`` into the C bridge representation.
///
/// For ``SlotSupplier/custom(_:)`` the caller must retain ``customBridge`` for the lifetime of
/// the worker so its consumer task can run; for the other variants it is `nil`.
struct BridgedSlotSupplier {
    let coreSupplier: TemporalCoreSlotSupplier
    let customBridge: BridgeCustomSlotSupplier?
}

extension TemporalCoreSlotSupplier {
    static func bridge(_ slotSupplier: SlotSupplier) -> BridgedSlotSupplier {
        var supplier = TemporalCoreSlotSupplier()
        var custom: BridgeCustomSlotSupplier?

        switch slotSupplier.kind {
        case .fixedSize(let fixedSize):
            supplier.tag = FixedSize
            supplier.fixed_size.num_slots = UInt(fixedSize.maximumSlots)

        case .resourceBased(let options, let tunerOptions):
            supplier.tag = ResourceBased
            supplier.resource_based.minimum_slots = UInt(options.minimumSlots)
            supplier.resource_based.maximum_slots = UInt(options.maximumSlots)
            supplier.resource_based.ramp_throttle_ms = options.rampThrottle.milliseconds
            supplier.resource_based.tuner_options.target_memory_usage = tunerOptions.targetMemoryUsage
            supplier.resource_based.tuner_options.target_cpu_usage = tunerOptions.targetCpuUsage

        case .custom(let customSupplier):
            let bridge = BridgeCustomSlotSupplier(customSupplier)
            custom = bridge
            supplier.tag = Custom
            supplier.custom._0 = bridge.callbacksPointer
        }

        return BridgedSlotSupplier(coreSupplier: supplier, customBridge: custom)
    }
}
