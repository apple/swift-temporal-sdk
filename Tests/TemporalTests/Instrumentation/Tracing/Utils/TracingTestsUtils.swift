//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Temporal SDK open source project
//
// Copyright (c) 2025 Apple Inc. and the Swift Temporal SDK project authors
// Licensed under MIT License
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Swift Cassandra Client project authors
//
// SPDX-License-Identifier: MIT
//
//===----------------------------------------------------------------------===//

import Synchronization
import Testing
import Tracing

/// Simle `Tracer` for testing usage.
final class TestTracer: Tracer {
    typealias Span = TestSpan

    private let testSpans: Mutex<[String: TestSpan]> = .init([:])

    func getSpan(ofOperation operationName: String) -> TestSpan? {
        self.testSpans.withLock { $0[operationName] }
    }

    func getEventsForTestSpan(ofOperation operationName: String) -> [SpanEvent] {
        self.getSpan(ofOperation: operationName)?.events ?? []
    }

    func extract<Carrier, Extract>(
        _ carrier: Carrier,
        into context: inout ServiceContextModule.ServiceContext,
        using extractor: Extract
    ) where Carrier == Extract.Carrier, Extract: Instrumentation.Extractor {
        let traceID = extractor.extract(key: TraceID.keyName, from: carrier)
        context[TraceID.self] = traceID
    }

    func inject<Carrier, Inject>(
        _ context: ServiceContextModule.ServiceContext,
        into carrier: inout Carrier,
        using injector: Inject
    ) where Carrier == Inject.Carrier, Inject: Instrumentation.Injector {
        if let traceID = context.traceID {
            injector.inject(traceID, forKey: TraceID.keyName, into: &carrier)
        }
    }

    func forceFlush() {
        // no-op
    }

    func startSpan<Instant>(
        _ operationName: String,
        context: @autoclosure () -> ServiceContext,
        ofKind kind: SpanKind,
        at instant: @autoclosure () -> Instant,
        function: String,
        file fileID: String,
        line: UInt
    ) -> TestSpan where Instant: TracerInstant {
        return self.testSpans.withLock { testSpans in
            let span = TestSpan(context: context(), operationName: operationName)
            testSpans[operationName] = span
            return span
        }
    }
}

final class TestSpan: Span, Sendable {
    private struct State {
        var context: ServiceContextModule.ServiceContext
        var operationName: String
        var attributes: Tracing.SpanAttributes
        var status: Tracing.SpanStatus?
        var events: [Tracing.SpanEvent] = []
        var errors: [TracingInterceptorTestError]
    }

    private let state: Mutex<State>
    let isRecording: Bool

    var context: ServiceContextModule.ServiceContext {
        self.state.withLock { $0.context }
    }

    var operationName: String {
        get { self.state.withLock { $0.operationName } }
        set { self.state.withLock { $0.operationName = newValue } }
    }

    var attributes: Tracing.SpanAttributes {
        get { self.state.withLock { $0.attributes } }
        set { self.state.withLock { $0.attributes = newValue } }
    }

    var events: [Tracing.SpanEvent] {
        self.state.withLock { $0.events }
    }

    var status: SpanStatus? {
        self.state.withLock { $0.status }
    }

    var errors: [TracingInterceptorTestError] {
        self.state.withLock { $0.errors }
    }

    init(
        context: ServiceContextModule.ServiceContext,
        operationName: String,
        attributes: Tracing.SpanAttributes = [:],
        isRecording: Bool = true
    ) {
        let state = State(
            context: context,
            operationName: operationName,
            attributes: attributes,
            errors: []
        )
        self.state = Mutex(state)
        self.isRecording = isRecording
    }

    func setStatus(_ status: Tracing.SpanStatus) {
        self.state.withLock { $0.status = status }
    }

    func addEvent(_ event: Tracing.SpanEvent) {
        self.state.withLock { $0.events.append(event) }
    }

    func recordError<Instant>(
        _ error: any Error,
        attributes: Tracing.SpanAttributes,
        at instant: @autoclosure () -> Instant
    ) where Instant: Tracing.TracerInstant {
        // For the purposes of these tests, we don't really care about the error being thrown
        self.state.withLock { $0.errors.append(TracingInterceptorTestError.testError) }
    }

    func addLink(_ link: Tracing.SpanLink) {
        self.state.withLock {
            $0.context.spanLinks?.append(link)
        }
    }

    func end<Instant>(at instant: @autoclosure () -> Instant) where Instant: Tracing.TracerInstant {
        // no-op
    }
}

enum TraceID: ServiceContextModule.ServiceContextKey {
    typealias Value = String

    static let keyName = "traceparent"  // matches default Temporal tracing key
}

enum ServiceContextSpanLinksKey: ServiceContextModule.ServiceContextKey {
    typealias Value = [SpanLink]

    static let keyName = "span-links"
}

extension ServiceContext {
    var traceID: String? {
        get {
            self[TraceID.self]
        }
        set {
            self[TraceID.self] = newValue
        }
    }

    var spanLinks: [SpanLink]? {
        get {
            self[ServiceContextSpanLinksKey.self]
        }
        set {
            self[ServiceContextSpanLinksKey.self] = newValue
        }
    }
}

struct TestSpanEvent: Equatable, CustomDebugStringConvertible {
    var name: String
    var attributes: SpanAttributes

    var debugDescription: String {
        var attributesDescription = ""
        // swift-format-ignore: ReplaceForEachWithForLoop
        self.attributes.forEach { key, value in
            attributesDescription += " \(key): \(value),"
        }

        return """
            (name: \(self.name), attributes: [\(attributesDescription)])
            """
    }

    init(_ name: String, _ attributes: SpanAttributes) {
        self.name = name
        self.attributes = attributes
    }

    init(_ spanEvent: SpanEvent) {
        self.name = spanEvent.name
        self.attributes = spanEvent.attributes
    }
}

enum TracingInterceptorTestError: Error, Equatable {
    case testError
}

func assertTestSpanComponents(
    forSpan spanName: String,
    tracer: TestTracer,
    assertEvents: ([TestSpanEvent]) -> Void,
    assertAttributes: (SpanAttributes) -> Void,
    assertStatus: (SpanStatus?) -> Void,
    assertErrors: ([TracingInterceptorTestError]) -> Void
) {
    guard let span = tracer.getSpan(ofOperation: spanName) else {
        Issue.record("Span could not be found")
        return
    }
    assertEvents(span.events.map({ TestSpanEvent($0) }))
    assertAttributes(span.attributes)
    assertStatus(span.status)
    assertErrors(span.errors)
}
