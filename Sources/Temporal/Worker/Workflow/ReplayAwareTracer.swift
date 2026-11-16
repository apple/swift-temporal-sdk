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

package import Tracing

/// A tracer that hands back non-recording spans while the workflow is replaying.
///
/// Workflow code runs again from the beginning on every replay, so without this every span started in
/// a workflow is exported once per replayed workflow task.
///
/// The tracer is generic over the tracer it wraps because `Tracer` carries an associated `Span` type,
/// which an existential cannot preserve. Use ``withReplayAwareTracer(_:_:)`` to wrap an `any Tracer`.
package struct ReplayAwareTracer<Underlying: Tracer>: Tracer {
    package typealias Span = ReplayAwareSpan<Underlying.Span>

    private let underlying: Underlying

    package init(underlying: Underlying) {
        self.underlying = underlying
    }

    package func startSpan<Instant: TracerInstant>(
        _ operationName: String,
        context: @autoclosure () -> ServiceContext,
        ofKind kind: SpanKind,
        at instant: @autoclosure () -> Instant,
        function: String,
        file fileID: String,
        line: UInt
    ) -> ReplayAwareSpan<Underlying.Span> {
        guard !isWorkflowReplaying() else {
            return .suppressed(NoOpTracer.NoOpSpan(context: context()))
        }
        return .recording(
            self.underlying.startSpan(
                operationName,
                context: context(),
                ofKind: kind,
                at: instant(),
                function: function,
                file: fileID,
                line: line
            )
        )
    }

    package func activeSpan(identifiedBy context: ServiceContext) -> ReplayAwareSpan<Underlying.Span>? {
        self.underlying.activeSpan(identifiedBy: context).map { .recording($0) }
    }

    @available(*, deprecated, message: "prefer withSpan")
    package func forceFlush() {
        self.underlying.forceFlush()
    }

    // Propagation carries no span data of its own, so it is forwarded during replay as well: workflow
    // code that injects headers while replaying still needs a well-formed carrier.

    package func inject<Carrier, Inject>(
        _ context: ServiceContext,
        into carrier: inout Carrier,
        using injector: Inject
    ) where Inject: Injector, Inject.Carrier == Carrier {
        self.underlying.inject(context, into: &carrier, using: injector)
    }

    package func extract<Carrier, Extract>(
        _ carrier: Carrier,
        into context: inout ServiceContext,
        using extractor: Extract
    ) where Extract: Extractor, Extract.Carrier == Carrier {
        self.underlying.extract(carrier, into: &context, using: extractor)
    }
}

/// A span that either records through the wrapped span or discards everything written to it.
///
/// `ReplayAwareTracer` decides which of the two a span is when it starts, so a span that began outside
/// a replay keeps recording even if the workflow later replays while the span is still open.
package enum ReplayAwareSpan<Wrapped: Tracing.Span>: Tracing.Span {
    /// A span started while the workflow was not replaying.
    case recording(Wrapped)
    /// A span started while the workflow was replaying.
    case suppressed(NoOpTracer.NoOpSpan)

    package var context: ServiceContext {
        switch self {
        case .recording(let span): span.context
        case .suppressed(let span): span.context
        }
    }

    package var isRecording: Bool {
        switch self {
        case .recording(let span): span.isRecording
        case .suppressed(let span): span.isRecording
        }
    }

    package var operationName: String {
        get {
            switch self {
            case .recording(let span): span.operationName
            case .suppressed(let span): span.operationName
            }
        }
        nonmutating set {
            switch self {
            case .recording(let span): span.operationName = newValue
            case .suppressed(let span): span.operationName = newValue
            }
        }
    }

    package var attributes: SpanAttributes {
        get {
            switch self {
            case .recording(let span): span.attributes
            case .suppressed(let span): span.attributes
            }
        }
        nonmutating set {
            switch self {
            case .recording(let span): span.attributes = newValue
            case .suppressed(let span): span.attributes = newValue
            }
        }
    }

    package func setStatus(_ status: SpanStatus) {
        switch self {
        case .recording(let span): span.setStatus(status)
        case .suppressed(let span): span.setStatus(status)
        }
    }

    package func addEvent(_ event: SpanEvent) {
        switch self {
        case .recording(let span): span.addEvent(event)
        case .suppressed(let span): span.addEvent(event)
        }
    }

    package func addLink(_ link: SpanLink) {
        switch self {
        case .recording(let span): span.addLink(link)
        case .suppressed(let span): span.addLink(link)
        }
    }

    package func recordError<Instant: TracerInstant>(
        _ error: any Error,
        attributes: SpanAttributes,
        at instant: @autoclosure () -> Instant
    ) {
        switch self {
        case .recording(let span): span.recordError(error, attributes: attributes, at: instant())
        case .suppressed(let span): span.recordError(error, attributes: attributes, at: instant())
        }
    }

    package func end<Instant: TracerInstant>(at instant: @autoclosure () -> Instant) {
        switch self {
        case .recording(let span): span.end(at: instant())
        case .suppressed(let span): span.end(at: instant())
        }
    }
}

/// Binds a replay-aware tracer wrapping `tracer` for the duration of `operation`.
///
/// This exists to open the `any Tracer` existential: `ReplayAwareTracer` needs the concrete tracer
/// type to name its `Span`.
package func withReplayAwareTracer<Result>(
    _ tracer: some Tracer,
    _ operation: () async throws -> Result
) async throws -> Result {
    try await withTracer(ReplayAwareTracer(underlying: tracer)) {
        try await operation()
    }
}
