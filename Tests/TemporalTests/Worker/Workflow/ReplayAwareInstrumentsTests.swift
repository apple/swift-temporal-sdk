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

import Metrics
import MetricsTestKit
import ServiceContextModule
import Temporal
import Testing
import Tracing

@Suite(.tags(.workflowTests))
struct ReplayAwareInstrumentsTests {

    // MARK: - Metrics

    @Test
    func counterRecordsOutsideAWorkflow() throws {
        let backend = TestMetrics()
        let factory = ReplayAwareMetricsFactory(underlying: backend)

        let counter = factory.makeCounter(label: "orders", dimensions: [])
        counter.increment(by: 3)
        counter.increment(by: 4)

        #expect(backend.counterTotal(label: "orders") == 7)
    }

    @Test
    func everyHandlerKindRecordsOutsideAWorkflow() throws {
        let backend = TestMetrics()
        let factory = ReplayAwareMetricsFactory(underlying: backend)

        factory.makeFloatingPointCounter(label: "fractional", dimensions: []).increment(by: 1.5)
        factory.makeMeter(label: "queue-depth", dimensions: []).set(Int64(12))
        factory.makeRecorder(label: "payload-size", dimensions: [], aggregate: true).record(Int64(2_048))
        factory.makeTimer(label: "latency", dimensions: []).recordNanoseconds(1_000)

        #expect(try backend.expectMeter("queue-depth").lastValue == 12)
        #expect(try backend.expectRecorder("payload-size").lastValue == 2_048)
        #expect(try backend.expectTimer("latency").lastValue == 1_000)
    }

    @Test
    func resetReachesTheUnderlyingCounterOutsideAWorkflow() throws {
        let backend = TestMetrics()
        let factory = ReplayAwareMetricsFactory(underlying: backend)

        let counter = factory.makeCounter(label: "retries", dimensions: [])
        counter.increment(by: 5)
        counter.reset()

        #expect(backend.counterTotal(label: "retries") == 0)
    }

    /// The backend matches a handler against its own bookkeeping, so `destroy` has to hand back the
    /// handler the backend made rather than the wrapper around it.
    @Test
    func destroyHandsTheBackendItsOwnHandler() throws {
        let backend = TestMetrics()
        let factory = ReplayAwareMetricsFactory(underlying: backend)

        let counter = factory.makeCounter(label: "transient", dimensions: [])
        counter.increment(by: 1)
        #expect(backend.counters(label: "transient").count == 1)

        factory.destroyCounter(counter)
        #expect(backend.counters(label: "transient").isEmpty)
    }

    @Test
    func destroyToleratesAHandlerItDidNotMake() throws {
        let backend = TestMetrics()
        let factory = ReplayAwareMetricsFactory(underlying: backend)

        // A handler made straight off the backend never passed through the wrapper.
        let foreign = backend.makeCounter(label: "foreign", dimensions: [])
        foreign.increment(by: 1)
        #expect(backend.counters(label: "foreign").count == 1)

        factory.destroyCounter(foreign)
        #expect(backend.counters(label: "foreign").isEmpty)
    }

    // MARK: - Tracing

    @Test
    func spanRecordsThroughTheWrappedTracerOutsideAWorkflow() throws {
        let backend = TestTracer()
        let tracer = ReplayAwareTracer(underlying: backend)

        let span = tracer.startSpan("charge-card")
        span.attributes["amount"] = 42
        span.end()

        guard case .recording = span else {
            Issue.record("expected a recording span outside a workflow, got \(span)")
            return
        }
        #expect(backend.getSpan(ofOperation: "charge-card") != nil)
    }

    @Test
    func propagationStillWorksThroughTheWrapper() throws {
        let backend = TestTracer()
        let tracer = ReplayAwareTracer(underlying: backend)

        var context = ServiceContext.topLevel
        context.traceID = "trace-abc"

        var carrier: [String: String] = [:]
        tracer.inject(context, into: &carrier, using: DictionaryInjector())

        var extracted = ServiceContext.topLevel
        tracer.extract(carrier, into: &extracted, using: DictionaryExtractor())

        #expect(extracted.traceID == "trace-abc")
    }

    /// A span started while replaying takes everything written to it and keeps none of it.
    @Test
    func suppressedSpanDiscardsEverythingWrittenToIt() throws {
        let span = ReplayAwareSpan<TestSpan>.suppressed(
            NoOpTracer.NoOpSpan(context: .topLevel)
        )

        #expect(span.isRecording == false)

        span.operationName = "renamed"
        span.attributes["key"] = "value"
        span.setStatus(SpanStatus(code: .error))
        span.addEvent(SpanEvent(name: "ignored"))
        span.recordError(TestInstrumentError.boom)
        span.end()

        #expect(span.operationName == "noop")
        #expect(span.attributes.isEmpty)
    }
}

private enum TestInstrumentError: Error {
    case boom
}

private struct DictionaryInjector: Injector {
    typealias Carrier = [String: String]

    func inject(_ value: String, forKey key: String, into carrier: inout Carrier) {
        carrier[key] = value
    }
}

private struct DictionaryExtractor: Extractor {
    typealias Carrier = [String: String]

    func extract(key: String, from carrier: Carrier) -> String? {
        carrier[key]
    }
}
