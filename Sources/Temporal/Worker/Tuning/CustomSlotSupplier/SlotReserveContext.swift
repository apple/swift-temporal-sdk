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

/// Contextual information passed to ``CustomSlotSupplier`` reservation requests.
public struct SlotReserveContext: Sendable {
    /// The kind of task the slot is being reserved for.
    public var slotType: SlotType
    /// The task queue name the worker is polling.
    public var taskQueue: String
    /// The worker identity reported to the Temporal server.
    public var workerIdentity: String
    /// The worker build identifier.
    public var workerBuildId: String
    /// `true` when the reservation is for the sticky workflow task queue.
    public var isSticky: Bool

    public init(
        slotType: SlotType,
        taskQueue: String,
        workerIdentity: String,
        workerBuildId: String,
        isSticky: Bool
    ) {
        self.slotType = slotType
        self.taskQueue = taskQueue
        self.workerIdentity = workerIdentity
        self.workerBuildId = workerBuildId
        self.isSticky = isSticky
    }
}
