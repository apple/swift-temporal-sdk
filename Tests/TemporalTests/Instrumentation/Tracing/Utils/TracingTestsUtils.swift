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

import InMemoryTracing
import Testing
import Tracing

/// The trace context that `InMemoryTracer` writes into, and reads from, the Temporal tracing header.
struct InMemoryTraceHeader: Codable {
    let traceID: String
    let spanID: String

    init(traceID: String, spanID: String) {
        self.traceID = traceID
        self.spanID = spanID
    }

    init(from decoder: any Decoder) throws {
        let values = try decoder.singleValueContainer().decode([String: String].self)
        guard let traceID = values[InMemoryTracer.traceIDKey], let spanID = values[InMemoryTracer.spanIDKey] else {
            throw DecodingError.dataCorrupted(
                .init(codingPath: decoder.codingPath, debugDescription: "Missing InMemoryTracer keys in \(values)")
            )
        }
        self.init(traceID: traceID, spanID: spanID)
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode([InMemoryTracer.traceIDKey: self.traceID, InMemoryTracer.spanIDKey: self.spanID])
    }
}

extension InMemoryTracer {
    /// Returns the most recently finished span with the given operation name.
    func finishedSpan(named operationName: String) -> FinishedInMemorySpan? {
        self.finishedSpans.last { $0.operationName == operationName }
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
    tracer: InMemoryTracer,
    assertEvents: ([TestSpanEvent]) -> Void,
    assertAttributes: (SpanAttributes) -> Void,
    assertStatus: (SpanStatus?) -> Void,
    assertErrors: ([TracingInterceptorTestError]) -> Void
) {
    guard let span = tracer.finishedSpan(named: spanName) else {
        if tracer.activeSpans.contains(where: { $0.operationName == spanName }) {
            Issue.record("Span \(spanName) was started but not ended")
        } else {
            Issue.record("Span \(spanName) could not be found")
        }
        return
    }
    assertEvents(span.events.map({ TestSpanEvent($0) }))
    assertAttributes(span.attributes)
    assertStatus(span.status)
    assertErrors(span.errors.compactMap { $0.error as? TracingInterceptorTestError })
}
