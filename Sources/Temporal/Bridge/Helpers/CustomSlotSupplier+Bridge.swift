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
import Foundation
import Synchronization

/// Bridges a user-provided `CustomSlotSupplier` to the Temporal core's C callback API.
///
/// This wrapper owns a heap-allocated `TemporalCoreCustomSlotSupplierCallbacks` whose
/// `user_data` field holds a retained reference to the wrapper. The callbacks struct is handed
/// to the Rust core via `TemporalCoreSlotSupplier` and freed by the core through the `free`
/// callback when the worker shuts down.
///
/// Asynchronous reservations are processed inside a long-lived structured task tree that the
/// owning worker spawns through ``runReserveLoop()``. Each reservation runs in its own task
/// group so that cancellations from the core can be propagated to the user's `reserveSlot`
/// implementation via Swift cooperative cancellation.
final class BridgeCustomSlotSupplier: Sendable {
    /// A boxed permit whose address is used as the FFI permit ID. Retain/release through
    /// `Unmanaged` avoids the need for a separate id-to-permit dictionary and its wraparound
    /// edge cases.
    private final class PermitBox: Sendable {
        let value: any Sendable
        init(_ value: any Sendable) { self.value = value }
    }

    private struct CancelState {
        var continuationsByKey: [UInt: CheckedContinuation<Void, Never>] = [:]
        var preCancelled: Set<UInt> = []
        /// Completion contexts we couldn't schedule (e.g. handleReserve arrived after
        /// shutdown). Stored as raw bit patterns because `OpaquePointer` is not Sendable but
        /// we only ever use these values as arguments to the C completion API.
        var orphanedReserves: Set<UInt> = []
        /// Keys currently owned by an in-flight `runOneReservation`. Used by
        /// `handleCancelReserve` to reject late cancel callbacks whose completion_ctx address
        /// has already been recycled by the core.
        var activeKeys: Set<UInt> = []
    }

    /// Bookkeeping used by the consumer loop to know when the reserve stream can be finished.
    /// The stream is only finished once shutdown has been requested and no reservations are
    /// in flight. Finishing earlier would silently drop reserve requests that Rust delivered
    /// concurrently with the shutdown call.
    private struct ShutdownState {
        var isShuttingDown: Bool = false
        var inFlight: UInt = 0
    }

    /// Pointers crossed at the FFI boundary; safe to send because we treat them as opaque keys.
    fileprivate struct ReserveRequest: @unchecked Sendable {
        var context: SlotReserveContext
        var completionCtx: OpaquePointer
    }

    private enum Outcome: Sendable {
        case reserved(any Sendable)
        case cancelledByCore
    }

    private let supplier: any CustomSlotSupplier

    private let cancelState: Mutex<CancelState> = .init(.init())
    private let shutdownState: Mutex<ShutdownState> = .init(.init())

    /// Pointer to the heap-allocated callbacks struct handed to the core. Released through the
    /// C `free` callback or, if the worker never took ownership, through ``tearDownWithoutCore()``.
    private nonisolated(unsafe) let callbacks: UnsafeMutablePointer<TemporalCoreCustomSlotSupplierCallbacks>

    /// Pointer to the callbacks struct, suitable for embedding in a ``TemporalCoreSlotSupplier``.
    var callbacksPointer: UnsafePointer<TemporalCoreCustomSlotSupplierCallbacks> {
        UnsafePointer(self.callbacks)
    }

    /// Stream of incoming reservation requests. A reserve C callback yields onto this stream;
    /// the consumer task in ``runReserveLoop()`` drains it.
    private let reserveStream: AsyncStream<ReserveRequest>
    private let reserveContinuation: AsyncStream<ReserveRequest>.Continuation

    init(_ supplier: any CustomSlotSupplier) {
        self.supplier = supplier
        let (stream, continuation) = AsyncStream<ReserveRequest>.makeStream()
        self.reserveStream = stream
        self.reserveContinuation = continuation

        let callbacksPtr = UnsafeMutablePointer<TemporalCoreCustomSlotSupplierCallbacks>.allocate(capacity: 1)
        self.callbacks = callbacksPtr
        callbacksPtr.initialize(
            to: TemporalCoreCustomSlotSupplierCallbacks(
                reserve: Self.cReserve,
                cancel_reserve: Self.cCancelReserve,
                try_reserve: Self.cTryReserve,
                mark_used: Self.cMarkUsed,
                release: Self.cRelease,
                available_slots: Self.cAvailableSlots,
                free: Self.cFree,
                user_data: nil
            )
        )
        // Retain self into user_data; the C `free` callback will release it once the core drops
        // the slot supplier. If the core never takes ownership (e.g. `temporal_core_worker_new`
        // fails), the owner must call ``tearDownWithoutCore()`` to reclaim these resources.
        callbacksPtr.pointee.user_data = Unmanaged.passRetained(self).toOpaque()
    }

    /// Signals that the worker is shutting down. Once every reservation currently in flight has
    /// completed via its Rust-issued `cancel_reserve`, the consumer loop's stream will be finished
    /// and the loop will exit. Idempotent.
    ///
    /// Requests that arrive after this call but before the core stops issuing them are still
    /// handled normally — the core will subsequently cancel each via its `cancel_reserve` callback,
    /// draining the pending set to zero.
    func markShutdown() {
        let shouldFinishNow = self.shutdownState.withLock { state -> Bool in
            state.isShuttingDown = true
            return state.inFlight == 0
        }
        if shouldFinishNow {
            self.reserveContinuation.finish()
        }
    }

    /// Reclaims the heap-allocated callbacks struct and the self-retain in `user_data` when
    /// the core never took ownership (e.g. `temporal_core_worker_new` failed). Must not be called
    /// once the callbacks have been handed to the core — the core owns the free at that point.
    func tearDownWithoutCore() {
        // Route through the same C free callback so ownership rules stay in one place.
        Self.cFree(self.callbacksPointer)
    }

    /// Drives the consumer task that processes reservation requests. This method runs until the
    /// reserve stream is finished, which happens once ``markShutdown()`` has been called and
    /// every in-flight reservation has completed.
    func runReserveLoop() async {
        await withDiscardingTaskGroup { group in
            for await request in self.reserveStream {
                group.addTask { [self] in
                    await self.runOneReservation(request)
                }
            }
            // The discarding task group awaits any still-running reservations before returning.
        }
    }

    // MARK: - Per-reservation handling

    private func runOneReservation(_ request: ReserveRequest) async {
        let key = UInt(bitPattern: request.completionCtx)
        let outcome = await withTaskGroup(of: Outcome.self, returning: Outcome.self) { group in
            group.addTask { [supplier, context = request.context] in
                // Per the Rust core contract, reserveSlot is not allowed to fail; if user code
                // throws for any reason other than cancellation, we back off briefly and retry.
                // Real cancellation is delivered exclusively through the cancel watcher below —
                // once the surrounding task is cancelled we exit through this branch and let
                // the watcher's `.cancelledByCore` outcome drive the FFI completion call.
                while true {
                    if Task.isCancelled { return .cancelledByCore }
                    do {
                        let permit = try await supplier.reserveSlot(context: context)
                        return .reserved(permit)
                    } catch {
                        // Sleep briefly to avoid busy-looping when user code throws repeatedly.
                        // `Task.sleep` observes cancellation, so if the surrounding task is
                        // cancelled we exit on the next `Task.isCancelled` check.
                        try? await Task.sleep(for: .milliseconds(100))
                    }
                }
            }
            group.addTask { [self] in
                await self.waitForCancelSignal(key: key)
                return .cancelledByCore
            }
            let first = await group.next()!
            group.cancelAll()
            await group.waitForAll()
            return first
        }

        // Drop all cancel state for this key. After this point `handleCancelReserve` will treat
        // any incoming cancel for this address as stale and drop it, so a completion_ctx address
        // that the core recycles for a new reservation cannot inherit our leftover bookkeeping.
        self.cancelState.withLock { state in
            state.activeKeys.remove(key)
            _ = state.continuationsByKey.removeValue(forKey: key)
            _ = state.preCancelled.remove(key)
        }

        switch outcome {
        case .reserved(let permit):
            let permitID = Self.encodePermit(permit)
            let completed = temporal_core_complete_async_reserve(request.completionCtx, permitID)
            if !completed {
                // Core cancelled the reservation while we were holding the permit; surrender it
                // and switch to the cancellation completion.
                Self.releasePermit(permitID)
                _ = temporal_core_complete_async_cancel_reserve(request.completionCtx)
            }
        case .cancelledByCore:
            _ = temporal_core_complete_async_cancel_reserve(request.completionCtx)
        }

        self.completeReservation()
    }

    /// Records the start of an incoming reservation. Returns `false` if the wrapper has already
    /// been asked to shut down and the request should be ignored.
    private func beginReservation() -> Bool {
        self.shutdownState.withLock { state in
            guard !state.isShuttingDown else { return false }
            state.inFlight &+= 1
            return true
        }
    }

    /// Marks a reservation as complete and finishes the reserve stream if shutdown is pending
    /// and no reservations remain in flight.
    private func completeReservation() {
        let shouldFinish = self.shutdownState.withLock { state -> Bool in
            state.inFlight &-= 1
            return state.isShuttingDown && state.inFlight == 0
        }
        if shouldFinish {
            self.reserveContinuation.finish()
        }
    }

    private func waitForCancelSignal(key: UInt) async {
        await withTaskCancellationHandler {
            await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
                let resumeReason = self.cancelState.withLock { state -> ResumeReason in
                    if state.preCancelled.remove(key) != nil {
                        return .preCancelled
                    }
                    state.continuationsByKey[key] = cont
                    return .registered
                }
                switch resumeReason {
                case .preCancelled:
                    cont.resume()
                case .registered:
                    // Post-registration cancellation check. `onCancel` may have fired between
                    // entering `withTaskCancellationHandler` and this insertion (finding an
                    // empty map and doing nothing); if the surrounding task is already cancelled
                    // we must resume the continuation ourselves.
                    if Task.isCancelled {
                        let cont = self.cancelState.withLock { $0.continuationsByKey.removeValue(forKey: key) }
                        cont?.resume()
                    }
                }
            }
        } onCancel: {
            let cont = self.cancelState.withLock { state in
                state.continuationsByKey.removeValue(forKey: key)
            }
            cont?.resume()
        }
    }

    private enum ResumeReason {
        case preCancelled
        case registered
    }

    // MARK: - Permit encoding
    //
    // Permits are boxed into a `PermitBox` and their retained `Unmanaged` pointer bits are used
    // as the FFI permit ID. This avoids a separate mapping table (and its wraparound edge case)
    // and guarantees identity: the ID that comes back in mark_used/release always refers to the
    // same permit value we handed out.

    private static func encodePermit(_ permit: any Sendable) -> UInt {
        let box = PermitBox(permit)
        let raw = Unmanaged.passRetained(box).toOpaque()
        // Pointer bits are guaranteed nonzero for a live allocation, so ID 0 stays reserved for
        // the "no permit" sentinel used by `try_reserve`.
        return UInt(bitPattern: raw)
    }

    /// Invokes `body` with the permit for `id`, holding an extra retain on the `PermitBox` for
    /// the duration of the call. Guards `mark_used` against a concurrent `release` freeing the
    /// box while user code is still reading it.
    private static func withPermit<T>(_ id: UInt, _ body: (any Sendable) -> T) -> T? {
        guard let raw = UnsafeMutableRawPointer(bitPattern: id) else { return nil }
        let unmanaged = Unmanaged<PermitBox>.fromOpaque(raw)
        _ = unmanaged.retain()
        defer { unmanaged.release() }
        return body(unmanaged.takeUnretainedValue().value)
    }

    private static func consumePermit(_ id: UInt) -> (any Sendable)? {
        guard let raw = UnsafeMutableRawPointer(bitPattern: id) else { return nil }
        return Unmanaged<PermitBox>.fromOpaque(raw).takeRetainedValue().value
    }

    private static func releasePermit(_ id: UInt) {
        guard let raw = UnsafeMutableRawPointer(bitPattern: id) else { return }
        Unmanaged<PermitBox>.fromOpaque(raw).release()
    }

    // MARK: - C-callback handlers

    fileprivate func handleReserve(context: SlotReserveContext, completionCtx: OpaquePointer) {
        let key = UInt(bitPattern: completionCtx)
        // If we can't accept new reservations, remember the completion context so we can answer
        // when Rust follows up with its `cancel_reserve` — the Rust contract forbids calling
        // `complete_async_cancel_reserve` before that callback, so we cannot short-circuit here.
        guard self.beginReservation() else {
            self.cancelState.withLock { state in
                _ = state.orphanedReserves.insert(key)
            }
            return
        }
        // Register the key as active BEFORE yielding so any concurrent `cancel_reserve` for this
        // reservation is accepted rather than dropped by `handleCancelReserve`.
        self.cancelState.withLock { state in
            _ = state.activeKeys.insert(key)
        }
        self.reserveContinuation.yield(.init(context: context, completionCtx: completionCtx))
    }

    fileprivate func handleCancelReserve(completionCtx: OpaquePointer) {
        let key = UInt(bitPattern: completionCtx)
        enum Action {
            case resume(CheckedContinuation<Void, Never>)
            case respondOrphan
            case remember
            case drop
        }
        let action: Action = self.cancelState.withLock { state in
            if state.orphanedReserves.remove(key) != nil {
                return .respondOrphan
            }
            // Reject cancels for keys we don't currently own. Rust must not send `cancel_reserve`
            // for a reservation we've already completed, so an "unknown" key implies either a
            // recycled completion_ctx address or a spurious late cancel — either way, dropping it
            // is safer than parking it in `preCancelled` where it could collide with a future
            // reservation at the same address.
            guard state.activeKeys.contains(key) else {
                return .drop
            }
            if let c = state.continuationsByKey.removeValue(forKey: key) {
                return .resume(c)
            }
            // Cancel signal arrived before the watcher registered; remember it so the watcher
            // sees it on registration. Cleared in `runOneReservation` on completion.
            state.preCancelled.insert(key)
            return .remember
        }
        switch action {
        case .resume(let cont):
            cont.resume()
        case .respondOrphan:
            _ = temporal_core_complete_async_cancel_reserve(completionCtx)
        case .remember, .drop:
            break
        }
    }

    fileprivate func handleTryReserve(context: SlotReserveContext) -> UInt {
        guard let permit = self.supplier.tryReserveSlot(context: context) else {
            return 0
        }
        return Self.encodePermit(permit)
    }

    fileprivate func handleMarkUsed(slotInfo: SlotInfo, permitId: UInt) {
        _ = Self.withPermit(permitId) { permit in
            Self.callMarkUsed(supplier: self.supplier, slotInfo: slotInfo, permit: permit)
        }
    }

    fileprivate func handleRelease(slotInfo: SlotInfo?, permitId: UInt) {
        guard let permit = Self.consumePermit(permitId) else { return }
        Self.callRelease(supplier: self.supplier, slotInfo: slotInfo, permit: permit)
    }

    fileprivate func handleAvailableSlots() -> Int? {
        self.supplier.availableSlots()
    }

    // Generic openers: `SlotMarkUsedContext<Permit>` / `SlotReleaseContext<Permit>` require the
    // concrete associated type, so we cannot invoke these directly on `any CustomSlotSupplier`.
    // Passing the existential through a generic parameter opens it and gives us `S.Permit`.
    // The force-cast is safe: the bridge only ever hands back permits produced by this supplier.
    private static func callMarkUsed<S: CustomSlotSupplier>(supplier: S, slotInfo: SlotInfo, permit: any Sendable) {
        supplier.markSlotUsed(context: .init(slotInfo: slotInfo, permit: permit as! S.Permit))
    }

    private static func callRelease<S: CustomSlotSupplier>(supplier: S, slotInfo: SlotInfo?, permit: any Sendable) {
        supplier.releaseSlot(context: .init(slotInfo: slotInfo, permit: permit as! S.Permit))
    }

    fileprivate func handleFree() {
        // Ensure the consumer loop exits even if `markShutdown` was never called (e.g. when the
        // core drops the supplier without going through the worker's shutdown path).
        self.reserveContinuation.finish()
    }

    // MARK: - C function pointers
    //
    // These are static `@convention(c)` closures so they can be passed to the C bridge. They
    // recover the wrapper instance from `user_data` via `Unmanaged` and forward to the
    // instance methods above.

    private static let cReserve: @convention(c) (
        UnsafePointer<TemporalCoreSlotReserveCtx>?,
        OpaquePointer?,
        UnsafeMutableRawPointer?
    ) -> Void = { ctxPtr, completionCtx, userData in
        guard let ctxPtr, let completionCtx, let userData else { return }
        let wrapper = Unmanaged<BridgeCustomSlotSupplier>.fromOpaque(userData).takeUnretainedValue()
        let context = SlotReserveContext(c: ctxPtr.pointee)
        wrapper.handleReserve(context: context, completionCtx: completionCtx)
    }

    private static let cCancelReserve: @convention(c) (
        OpaquePointer?,
        UnsafeMutableRawPointer?
    ) -> Void = { completionCtx, userData in
        guard let completionCtx, let userData else { return }
        let wrapper = Unmanaged<BridgeCustomSlotSupplier>.fromOpaque(userData).takeUnretainedValue()
        wrapper.handleCancelReserve(completionCtx: completionCtx)
    }

    private static let cTryReserve: @convention(c) (
        UnsafePointer<TemporalCoreSlotReserveCtx>?,
        UnsafeMutableRawPointer?
    ) -> UInt = { ctxPtr, userData in
        guard let ctxPtr, let userData else { return 0 }
        let wrapper = Unmanaged<BridgeCustomSlotSupplier>.fromOpaque(userData).takeUnretainedValue()
        let context = SlotReserveContext(c: ctxPtr.pointee)
        return wrapper.handleTryReserve(context: context)
    }

    private static let cMarkUsed: @convention(c) (
        UnsafePointer<TemporalCoreSlotMarkUsedCtx>?,
        UnsafeMutableRawPointer?
    ) -> Void = { ctxPtr, userData in
        guard let ctxPtr, let userData else { return }
        let wrapper = Unmanaged<BridgeCustomSlotSupplier>.fromOpaque(userData).takeUnretainedValue()
        let info = SlotInfo(c: ctxPtr.pointee.slot_info)
        wrapper.handleMarkUsed(slotInfo: info, permitId: ctxPtr.pointee.slot_permit)
    }

    private static let cRelease: @convention(c) (
        UnsafePointer<TemporalCoreSlotReleaseCtx>?,
        UnsafeMutableRawPointer?
    ) -> Void = { ctxPtr, userData in
        guard let ctxPtr, let userData else { return }
        let wrapper = Unmanaged<BridgeCustomSlotSupplier>.fromOpaque(userData).takeUnretainedValue()
        let info: SlotInfo? = ctxPtr.pointee.slot_info.map { SlotInfo(c: $0.pointee) }
        wrapper.handleRelease(slotInfo: info, permitId: ctxPtr.pointee.slot_permit)
    }

    private static let cAvailableSlots: @convention(c) (
        UnsafeMutablePointer<UInt>?,
        UnsafeMutableRawPointer?
    ) -> Bool = { outPtr, userData in
        guard let outPtr, let userData else { return false }
        let wrapper = Unmanaged<BridgeCustomSlotSupplier>.fromOpaque(userData).takeUnretainedValue()
        guard let count = wrapper.handleAvailableSlots() else { return false }
        outPtr.pointee = UInt(max(0, count))
        return true
    }

    private static let cFree: @convention(c) (
        UnsafePointer<TemporalCoreCustomSlotSupplierCallbacks>?
    ) -> Void = { callbacksPtr in
        guard let callbacksPtr else { return }
        let userData = callbacksPtr.pointee.user_data
        if let userData {
            let wrapper = Unmanaged<BridgeCustomSlotSupplier>.fromOpaque(userData).takeRetainedValue()
            wrapper.handleFree()
        }
        // Free the heap-allocated callbacks struct itself.
        let mutable = UnsafeMutablePointer(mutating: callbacksPtr)
        mutable.deinitialize(count: 1)
        mutable.deallocate()
    }
}

// MARK: - C-to-Swift context conversions

extension SlotReserveContext {
    fileprivate init(c: TemporalCoreSlotReserveCtx) {
        let slotType: SlotType = switch c.slot_type {
        case WorkflowSlotKindType: .workflow
        case ActivitySlotKindType: .activity
        case LocalActivitySlotKindType: .localActivity
        case NexusSlotKindType: .nexus
        default: .activity
        }
        self.init(
            slotType: slotType,
            taskQueue: String(byteArrayRef: c.task_queue),
            workerIdentity: String(byteArrayRef: c.worker_identity),
            workerBuildId: String(byteArrayRef: c.worker_build_id),
            isSticky: c.is_sticky
        )
    }
}

extension SlotInfo {
    fileprivate init(c: TemporalCoreSlotInfo) {
        switch c.tag {
        case WorkflowSlotInfo:
            self = .workflow(
                workflowType: String(byteArrayRef: c.workflow_slot_info.workflow_type),
                isSticky: c.workflow_slot_info.is_sticky
            )
        case ActivitySlotInfo:
            self = .activity(
                activityType: String(byteArrayRef: c.activity_slot_info.activity_type)
            )
        case LocalActivitySlotInfo:
            self = .localActivity(
                activityType: String(byteArrayRef: c.local_activity_slot_info.activity_type)
            )
        case NexusSlotInfo:
            self = .nexus(
                service: String(byteArrayRef: c.nexus_slot_info.service),
                operation: String(byteArrayRef: c.nexus_slot_info.operation)
            )
        default:
            self = .activity(activityType: "")
        }
    }
}
