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

extension TemporalCoreSlotSupplier {
    init(_ slotSupplier: SlotSupplier) {
        var supplier = TemporalCoreSlotSupplier()
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
        }
        self = supplier
    }
}
