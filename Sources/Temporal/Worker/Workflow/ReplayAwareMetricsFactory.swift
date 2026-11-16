//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Temporal SDK open source project
//
// Copyright (c) 2025 Apple Inc. and the Swift Temporal SDK project authors
// Licensed under MIT License
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Swift Temporal SDK project authors
//
// SPDX-License-Identifier: MIT
//
//===----------------------------------------------------------------------===//

package import Metrics

/// A metrics factory whose handlers drop values while the workflow is replaying.
///
/// Workflow code runs again from the beginning on every replay, so without this every counter
/// increment and every recorded value in a workflow is emitted once per replayed workflow task.
///
/// The replay check happens when a value is recorded rather than when a handler is made: a handler
/// created during one activation stays in use across later activations, some of which replay.
package struct ReplayAwareMetricsFactory: MetricsFactory {
    private let underlying: any MetricsFactory

    package init(underlying: any MetricsFactory) {
        self.underlying = underlying
    }

    package func makeCounter(label: String, dimensions: [(String, String)]) -> any CounterHandler {
        ReplayAwareCounterHandler(underlying: self.underlying.makeCounter(label: label, dimensions: dimensions))
    }

    package func makeFloatingPointCounter(
        label: String,
        dimensions: [(String, String)]
    ) -> any FloatingPointCounterHandler {
        ReplayAwareFloatingPointCounterHandler(
            underlying: self.underlying.makeFloatingPointCounter(label: label, dimensions: dimensions)
        )
    }

    package func makeMeter(label: String, dimensions: [(String, String)]) -> any MeterHandler {
        ReplayAwareMeterHandler(underlying: self.underlying.makeMeter(label: label, dimensions: dimensions))
    }

    package func makeRecorder(
        label: String,
        dimensions: [(String, String)],
        aggregate: Bool
    ) -> any RecorderHandler {
        ReplayAwareRecorderHandler(
            underlying: self.underlying.makeRecorder(label: label, dimensions: dimensions, aggregate: aggregate)
        )
    }

    package func makeTimer(label: String, dimensions: [(String, String)]) -> any TimerHandler {
        ReplayAwareTimerHandler(underlying: self.underlying.makeTimer(label: label, dimensions: dimensions))
    }

    // The handler handed back to the backend has to be the one it made, not our wrapper, otherwise it
    // cannot match it against its own bookkeeping.

    package func destroyCounter(_ handler: any CounterHandler) {
        self.underlying.destroyCounter((handler as? ReplayAwareCounterHandler)?.underlying ?? handler)
    }

    package func destroyFloatingPointCounter(_ handler: any FloatingPointCounterHandler) {
        self.underlying.destroyFloatingPointCounter(
            (handler as? ReplayAwareFloatingPointCounterHandler)?.underlying ?? handler
        )
    }

    package func destroyMeter(_ handler: any MeterHandler) {
        self.underlying.destroyMeter((handler as? ReplayAwareMeterHandler)?.underlying ?? handler)
    }

    package func destroyRecorder(_ handler: any RecorderHandler) {
        self.underlying.destroyRecorder((handler as? ReplayAwareRecorderHandler)?.underlying ?? handler)
    }

    package func destroyTimer(_ handler: any TimerHandler) {
        self.underlying.destroyTimer((handler as? ReplayAwareTimerHandler)?.underlying ?? handler)
    }
}

package final class ReplayAwareCounterHandler: CounterHandler {
    package let underlying: any CounterHandler

    package init(underlying: any CounterHandler) {
        self.underlying = underlying
    }

    package func increment(by amount: Int64) {
        guard !isWorkflowReplaying() else { return }
        self.underlying.increment(by: amount)
    }

    package func reset() {
        guard !isWorkflowReplaying() else { return }
        self.underlying.reset()
    }
}

package final class ReplayAwareFloatingPointCounterHandler: FloatingPointCounterHandler {
    package let underlying: any FloatingPointCounterHandler

    package init(underlying: any FloatingPointCounterHandler) {
        self.underlying = underlying
    }

    package func increment(by amount: Double) {
        guard !isWorkflowReplaying() else { return }
        self.underlying.increment(by: amount)
    }

    package func reset() {
        guard !isWorkflowReplaying() else { return }
        self.underlying.reset()
    }
}

package final class ReplayAwareMeterHandler: MeterHandler {
    package let underlying: any MeterHandler

    package init(underlying: any MeterHandler) {
        self.underlying = underlying
    }

    package func set(_ value: Int64) {
        guard !isWorkflowReplaying() else { return }
        self.underlying.set(value)
    }

    package func set(_ value: Double) {
        guard !isWorkflowReplaying() else { return }
        self.underlying.set(value)
    }

    package func increment(by amount: Double) {
        guard !isWorkflowReplaying() else { return }
        self.underlying.increment(by: amount)
    }

    package func decrement(by amount: Double) {
        guard !isWorkflowReplaying() else { return }
        self.underlying.decrement(by: amount)
    }
}

package final class ReplayAwareRecorderHandler: RecorderHandler {
    package let underlying: any RecorderHandler

    package init(underlying: any RecorderHandler) {
        self.underlying = underlying
    }

    package func record(_ value: Int64) {
        guard !isWorkflowReplaying() else { return }
        self.underlying.record(value)
    }

    package func record(_ value: Double) {
        guard !isWorkflowReplaying() else { return }
        self.underlying.record(value)
    }
}

package final class ReplayAwareTimerHandler: TimerHandler {
    package let underlying: any TimerHandler

    package init(underlying: any TimerHandler) {
        self.underlying = underlying
    }

    package func recordNanoseconds(_ duration: Int64) {
        guard !isWorkflowReplaying() else { return }
        self.underlying.recordNanoseconds(duration)
    }

    package func preferDisplayUnit(_ unit: TimeUnit) {
        // A display preference carries no sample, so it is forwarded during replay as well.
        self.underlying.preferDisplayUnit(unit)
    }
}
