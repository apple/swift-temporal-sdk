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

/// A user-provided slot supplier that controls how task processing slots are reserved and released.
///
/// Conform to this protocol to plug custom slot allocation logic into a worker. The type is
/// invoked from the worker's bridge layer whenever the Temporal core needs to reserve, mark,
/// or release a slot for a workflow, activity, or local activity task.
///
/// ## Threading and concurrency
///
/// All requirements may be invoked concurrently from multiple tasks; conformers must be thread
/// safe. ``reserveSlot(context:)`` is asynchronous and should suspend until a slot is available.
/// It must observe Swift task cancellation and throw `CancellationError` when cancelled,
/// otherwise the worker cannot shut down promptly. ``tryReserveSlot(context:)``, ``markSlotUsed(context:)``,
/// ``releaseSlot(context:)``, and ``availableSlots()`` must not block.
///
/// ## Permits
///
/// Conformers choose any `Sendable` permit type to track an outstanding reservation. The same
/// permit value returned from ``reserveSlot(context:)`` or ``tryReserveSlot(context:)`` is later
/// passed back to ``markSlotUsed(context:)`` and ``releaseSlot(context:)``. The SDK assigns each
/// permit an opaque identifier when it crosses the FFI boundary and restores the original permit
/// value before invoking the mark-used or release callbacks.
public protocol CustomSlotSupplier: Sendable {
    /// The permit type used to track an outstanding reservation.
    associatedtype Permit: Sendable

    /// Reserves a slot, awaiting until one becomes available.
    ///
    /// The Temporal core invokes this method when it wants to poll for a new task. The
    /// implementation must suspend until a slot can be granted, and must propagate Swift task
    /// cancellation by throwing ``CancellationError``. Reservations are not allowed to fail; if
    /// an unrecoverable error is encountered the implementation should keep retrying until it
    /// succeeds or until cancellation is observed.
    ///
    /// - Parameter context: Information about the reservation request.
    /// - Returns: A permit representing the reserved slot.
    /// - Throws: ``CancellationError`` when the surrounding task is cancelled.
    func reserveSlot(context: SlotReserveContext) async throws -> Permit

    /// Attempts to reserve a slot synchronously.
    ///
    /// The Temporal core invokes this method when it wants to opportunistically grab a slot
    /// without suspending. Implementations must return immediately. Returning `nil` indicates
    /// that no slot is currently available.
    ///
    /// - Parameter context: Information about the reservation request.
    /// - Returns: A permit if a slot can be reserved without waiting, otherwise `nil`.
    func tryReserveSlot(context: SlotReserveContext) -> Permit?

    /// Marks a previously reserved slot as actively running a task.
    ///
    /// Invoked after ``reserveSlot(context:)`` or ``tryReserveSlot(context:)`` succeed and the
    /// reserved slot has been bound to a specific task.
    ///
    /// - Parameter context: The slot info and permit returned from the matching reserve call.
    func markSlotUsed(context: SlotMarkUsedContext<Permit>)

    /// Releases a previously reserved slot.
    ///
    /// Invoked when a reserved slot is no longer needed, either because the task it was bound
    /// to has completed or because the reservation was abandoned without ever being marked
    /// used. ``SlotReleaseContext/slotInfo`` is `nil` in the latter case.
    ///
    /// - Parameter context: The optional slot info and permit returned from the matching reserve call.
    func releaseSlot(context: SlotReleaseContext<Permit>)

    /// Reports the number of slots currently available, if known.
    ///
    /// The default implementation returns `nil`, indicating that the available slot count is
    /// unknown.
    func availableSlots() -> Int?
}

extension CustomSlotSupplier {
    public func availableSlots() -> Int? { nil }
}
