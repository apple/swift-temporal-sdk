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

/// Contextual information passed to ``CustomSlotSupplier/releaseSlot(context:)``.
public struct SlotReleaseContext<Permit: Sendable>: Sendable {
    /// Information about the task that occupied the slot, or `nil` when the reservation is
    /// released without ever being marked used.
    public var slotInfo: SlotInfo?
    /// The permit returned from the matching reserve call.
    public var permit: Permit

    public init(slotInfo: SlotInfo?, permit: Permit) {
        self.slotInfo = slotInfo
        self.permit = permit
    }
}
