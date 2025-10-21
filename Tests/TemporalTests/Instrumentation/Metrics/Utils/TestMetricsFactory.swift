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

import CoreMetrics
import Foundation
import Metrics
import Synchronization

/// Taken and adjusted from `swift-cluster-memberships`s own test target package.
///
/// Metrics factory which allows inspecting recorded metrics programmatically.
/// Only intended for tests of the Metrics API itself.
///
/// Created Handlers will store Metrics until they are explicitly destroyed.
final class TestMetricsFactory: MetricsFactory {
    typealias Label = String
    typealias Dimensions = String

    struct FullKey: Sendable {
        let label: Label
        let dimensions: [(String, String)]
    }

    private let _counters = Mutex<[FullKey: TestCounter]>([:])
    private let _meters = Mutex<[FullKey: TestMeter]>([:])
    private let _recorders = Mutex<[FullKey: TestRecorder]>([:])
    private let _timers = Mutex<[FullKey: TestTimer]>([:])

    init() {
        // nothing to do
    }

    /// Reset method to destroy all created ``TestCounter``, ``TestMeter``, ``TestRecorder`` and ``TestTimer``.
    ///
    /// Invoke this method in between test runs to verify that Counters are created as needed.
    func reset() {
        self._counters.withLock { $0.removeAll() }
        self._recorders.withLock { $0.removeAll() }
        self._meters.withLock { $0.removeAll() }
        self._timers.withLock { $0.removeAll() }
    }

    func makeCounter(label: String, dimensions: [(String, String)]) -> any CounterHandler {
        self._counters.withLock { counters in
            if let existing = counters[.init(label: label, dimensions: dimensions)] {
                return existing
            }
            let item = TestCounter(label: label, dimensions: dimensions)
            counters[.init(label: label, dimensions: dimensions)] = item
            return item
        }
    }

    func makeMeter(label: String, dimensions: [(String, String)]) -> any MeterHandler {
        self._meters.withLock { meters in
            if let existing = meters[.init(label: label, dimensions: dimensions)] {
                return existing
            }
            let item = TestMeter(label: label, dimensions: dimensions)
            meters[.init(label: label, dimensions: dimensions)] = item
            return item
        }
    }

    func makeRecorder(label: String, dimensions: [(String, String)], aggregate: Bool) -> any RecorderHandler {
        self._recorders.withLock { recorders in
            if let existing = recorders[.init(label: label, dimensions: dimensions)] {
                return existing
            }
            let item = TestRecorder(label: label, dimensions: dimensions, aggregate: aggregate)
            recorders[.init(label: label, dimensions: dimensions)] = item
            return item
        }
    }

    func makeTimer(label: String, dimensions: [(String, String)]) -> any TimerHandler {
        self._timers.withLock { timers in
            if let existing = timers[.init(label: label, dimensions: dimensions)] {
                return existing
            }
            let item = TestTimer(label: label, dimensions: dimensions)
            timers[.init(label: label, dimensions: dimensions)] = item
            return item
        }
    }

    func destroyCounter(_ handler: any CounterHandler) {
        if let testCounter = handler as? TestCounter {
            _ = self._counters.withLock { counters in
                counters.removeValue(forKey: testCounter.key)
            }
        }
    }

    func destroyMeter(_ handler: any MeterHandler) {
        if let testMeter = handler as? TestMeter {
            _ = self._meters.withLock { meters in
                meters.removeValue(forKey: testMeter.key)
            }
        }
    }

    func destroyRecorder(_ handler: any RecorderHandler) {
        if let testRecorder = handler as? TestRecorder {
            _ = self._recorders.withLock { recorders in
                recorders.removeValue(forKey: testRecorder.key)
            }
        }
    }

    func destroyTimer(_ handler: any TimerHandler) {
        if let testTimer = handler as? TestTimer {
            _ = self._timers.withLock { timers in
                timers.removeValue(forKey: testTimer.key)
            }
        }
    }
}

extension TestMetricsFactory.FullKey: Hashable {
    func hash(into hasher: inout Hasher) {
        self.label.hash(into: &hasher)
        for dim in self.dimensions {
            dim.0.hash(into: &hasher)
            dim.1.hash(into: &hasher)
        }
    }

    static func == (lhs: TestMetricsFactory.FullKey, rhs: TestMetricsFactory.FullKey) -> Bool {
        lhs.label == rhs.label
            && Dictionary(uniqueKeysWithValues: lhs.dimensions) == Dictionary(uniqueKeysWithValues: rhs.dimensions)
    }
}

// MARK: - Assertions

extension TestMetricsFactory {
    // MARK: - Counter

    func expectCounter(_ metric: Counter) throws -> TestCounter {
        guard let counter = metric._handler as? TestCounter else {
            throw TestMetricsError.illegalMetricType(metric: metric._handler, expected: "\(TestCounter.self)")
        }
        return counter
    }

    func expectCounter(_ label: String, _ dimensions: [(String, String)] = []) throws -> TestCounter {
        let maybeItem = self._counters.withLock { counters in
            counters[.init(label: label, dimensions: dimensions)]
        }
        guard let testCounter = maybeItem else {
            throw TestMetricsError.missingMetric(label: label, dimensions: dimensions)
        }
        return testCounter
    }

    /// All the counters which have been created and not destroyed.
    var counters: [TestCounter] {
        let counters = self._counters.withLock { $0 }
        return Array(counters.values)
    }

    // MARK: - Gauge

    func expectGauge(_ metric: Gauge) throws -> TestRecorder {
        try self.expectRecorder(metric)
    }

    func expectGauge(_ label: String, _ dimensions: [(String, String)] = []) throws -> TestRecorder {
        try self.expectRecorder(label, dimensions)
    }

    // MARK: - Meter

    func expectMeter(_ metric: Meter) throws -> TestMeter {
        guard let meter = metric._handler as? TestMeter else {
            throw TestMetricsError.illegalMetricType(metric: metric._handler, expected: "\(TestMeter.self)")
        }
        return meter
    }

    func expectMeter(_ label: String, _ dimensions: [(String, String)] = []) throws -> TestMeter {
        let maybeItem = self._meters.withLock { meters in
            meters[.init(label: label, dimensions: dimensions)]
        }
        guard let testMeter = maybeItem else {
            throw TestMetricsError.missingMetric(label: label, dimensions: dimensions)
        }
        return testMeter
    }

    /// All the meters which have been created and not destroyed.
    var meters: [TestMeter] {
        let meters = self._meters.withLock { $0 }
        return Array(meters.values)
    }

    // MARK: - Recorder

    func expectRecorder(_ metric: Recorder) throws -> TestRecorder {
        guard let recorder = metric._handler as? TestRecorder else {
            throw TestMetricsError.illegalMetricType(metric: metric._handler, expected: "\(TestRecorder.self)")
        }
        return recorder
    }

    func expectRecorder(_ label: String, _ dimensions: [(String, String)] = []) throws -> TestRecorder {
        let maybeItem = self._recorders.withLock { recorders in
            recorders[.init(label: label, dimensions: dimensions)]
        }
        guard let testRecorder = maybeItem else {
            throw TestMetricsError.missingMetric(label: label, dimensions: dimensions)
        }
        return testRecorder
    }

    /// All the recorders which have been created and not destroyed.
    var recorders: [TestRecorder] {
        let recorders = self._recorders.withLock { $0 }
        return Array(recorders.values)
    }

    // MARK: - Timer

    func expectTimer(_ metric: CoreMetrics.Timer) throws -> TestTimer {
        guard let timer = metric._handler as? TestTimer else {
            throw TestMetricsError.illegalMetricType(metric: metric._handler, expected: "\(TestTimer.self)")
        }
        return timer
    }

    func expectTimer(_ label: String, _ dimensions: [(String, String)] = []) throws -> TestTimer {
        let maybeItem = self._timers.withLock { timers in
            timers[.init(label: label, dimensions: dimensions)]
        }
        guard let testTimer = maybeItem else {
            throw TestMetricsError.missingMetric(label: label, dimensions: dimensions)
        }
        return testTimer
    }

    /// All the timers which have been created and not destroyed.
    var timers: [TestTimer] {
        let timers = self._timers.withLock { $0 }
        return Array(timers.values)
    }
}

// MARK: - Metric type implementations

protocol TestMetric {
    associatedtype Value

    var key: TestMetricsFactory.FullKey { get }

    var lastValue: Value? { get }
    var last: (Date, Value)? { get }
}

final class TestCounter: TestMetric, CounterHandler, Equatable {
    let id: String
    let label: String
    let dimensions: [(String, String)]

    var key: TestMetricsFactory.FullKey {
        TestMetricsFactory.FullKey(label: self.label, dimensions: self.dimensions)
    }

    private let _values = Mutex<[(Date, Int64)]>([])

    init(label: String, dimensions: [(String, String)]) {
        self.id = UUID().uuidString
        self.label = label
        self.dimensions = dimensions
    }

    func increment(by amount: Int64) {
        self._values.withLock { values in
            values.append((Date(), amount))
        }
    }

    func reset() {
        self._values.withLock { values in
            values = []
        }
    }

    var lastValue: Int64? {
        self.last?.1
    }

    var totalValue: Int64 {
        self.values.reduce(0, +)
    }

    var last: (Date, Int64)? {
        self._values.withLock { values in
            values.last
        }
    }

    var values: [Int64] {
        self._values.withLock { values in
            values.map { $0.1 }
        }
    }

    static func == (lhs: TestCounter, rhs: TestCounter) -> Bool {
        lhs.id == rhs.id
    }
}

final class TestMeter: TestMetric, MeterHandler, Equatable {
    let id: String
    let label: String
    let dimensions: [(String, String)]

    var key: TestMetricsFactory.FullKey {
        TestMetricsFactory.FullKey(label: self.label, dimensions: self.dimensions)
    }

    private let _values = Mutex<[(Date, Double)]>([])

    init(label: String, dimensions: [(String, String)]) {
        self.id = UUID().uuidString
        self.label = label
        self.dimensions = dimensions
    }

    func set(_ value: Int64) {
        self.set(Double(value))
    }

    func set(_ value: Double) {
        self._values.withLock { values in
            // this may lose precision but good enough as an example
            values.append((Date(), Double(value)))
        }
    }

    func increment(by amount: Double) {
        // Drop illegal values
        // - cannot increment by NaN
        guard !amount.isNaN else {
            return
        }
        // - cannot increment by infinite quantities
        guard !amount.isInfinite else {
            return
        }
        // - cannot increment by negative values
        guard amount.sign == .plus else {
            return
        }
        // - cannot increment by zero
        guard !amount.isZero else {
            return
        }

        self._values.withLock { values in
            let lastValue: Double = values.last?.1 ?? 0
            let newValue = lastValue + amount
            values.append((Date(), newValue))
        }
    }

    func decrement(by amount: Double) {
        // Drop illegal values
        // - cannot decrement by NaN
        guard !amount.isNaN else {
            return
        }
        // - cannot decrement by infinite quantities
        guard !amount.isInfinite else {
            return
        }
        // - cannot decrement by negative values
        guard amount.sign == .plus else {
            return
        }
        // - cannot decrement by zero
        guard !amount.isZero else {
            return
        }

        self._values.withLock { values in
            let lastValue: Double = values.last?.1 ?? 0
            let newValue = lastValue - amount
            values.append((Date(), newValue))
        }
    }

    var lastValue: Double? {
        self.last?.1
    }

    var last: (Date, Double)? {
        self._values.withLock { values in
            values.last
        }
    }

    var values: [Double] {
        self._values.withLock { values in
            values.map { $0.1 }
        }
    }

    static func == (lhs: TestMeter, rhs: TestMeter) -> Bool {
        lhs.id == rhs.id
    }
}

final class TestRecorder: TestMetric, RecorderHandler, Equatable {
    let id: String
    let label: String
    let dimensions: [(String, String)]
    let aggregate: Bool

    var key: TestMetricsFactory.FullKey {
        TestMetricsFactory.FullKey(label: self.label, dimensions: self.dimensions)
    }

    private let _values = Mutex<[(Date, Double)]>([])

    init(label: String, dimensions: [(String, String)], aggregate: Bool) {
        self.id = UUID().uuidString
        self.label = label
        self.dimensions = dimensions
        self.aggregate = aggregate
    }

    func record(_ value: Int64) {
        self.record(Double(value))
    }

    func record(_ value: Double) {
        self._values.withLock { values in
            // this may lose precision but good enough as an example
            values.append((Date(), Double(value)))
        }
    }

    var lastValue: Double? {
        self.last?.1
    }

    var last: (Date, Double)? {
        self._values.withLock { values in
            values.last
        }
    }

    var values: [Double] {
        self._values.withLock { values in
            values.map { $0.1 }
        }
    }

    static func == (lhs: TestRecorder, rhs: TestRecorder) -> Bool {
        lhs.id == rhs.id
    }
}

final class TestTimer: TestMetric, TimerHandler, Equatable {
    let id: String
    let label: String
    let displayUnit = Mutex<TimeUnit?>(nil)
    let dimensions: [(String, String)]

    var key: TestMetricsFactory.FullKey {
        TestMetricsFactory.FullKey(label: self.label, dimensions: self.dimensions)
    }

    private let _values = Mutex<[(Date, Int64)]>([])

    init(label: String, dimensions: [(String, String)]) {
        self.id = UUID().uuidString
        self.label = label
        self.dimensions = dimensions
    }

    func preferDisplayUnit(_ unit: TimeUnit) {
        self.displayUnit.withLock { displayUnit in
            displayUnit = unit
        }
    }

    func valueInPreferredUnit(atIndex i: Int) -> Double {
        let value = self.values[i]
        let displayUnit = self.displayUnit.withLock { $0 }
        guard let displayUnit else {
            return Double(value)
        }
        return Double(value) / Double(displayUnit.scaleFromNanoseconds)
    }

    func recordNanoseconds(_ duration: Int64) {
        self._values.withLock { values in
            values.append((Date(), duration))
        }
    }

    var lastValue: Int64? {
        self.last?.1
    }

    var values: [Int64] {
        self._values.withLock { values in
            values.map { $0.1 }
        }
    }

    var last: (Date, Int64)? {
        self._values.withLock { values in
            values.last
        }
    }

    static func == (lhs: TestTimer, rhs: TestTimer) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Errors

enum TestMetricsError: Error {
    case missingMetric(label: String, dimensions: [(String, String)])
    case illegalMetricType(metric: any Sendable, expected: String)
}

// MARK: - Sendable support

extension TestMetricsFactory: Sendable {}
extension TestCounter: Sendable {}
extension TestMeter: Sendable {}
extension TestRecorder: Sendable {}
extension TestTimer: Sendable {}
