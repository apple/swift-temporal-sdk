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

import Tracing

struct TemporalTraceRecording {
    /// `Injector` injecting the context into the Temporal request headers.
    private let injector = TemporalHeaderInjector()
    /// `Extractor` extracting the context from the Temporal response headers.
    private let extractor = TemporalHeaderExtractor()
    /// `Tracer` that creates the new trace spans.
    private let tracer: any Tracer
    /// The name of the Temporal tracing header key.
    private var tracingHeaderKey: String

    /// Creates a new trace recording utility.
    /// - Parameters:
    ///   - tracer: The `Tracer` that creates the new trace spans.
    ///   - tracingHeaderKey: The name of the Temporal tracing header key.
    init<T: Tracer>(tracer: T, tracingHeaderKey: String) {
        self.tracer = tracer
        self.tracingHeaderKey = tracingHeaderKey
    }

    // MARK: Outbound

    func recordOutbound<R: Sendable>(
        spanName: String,
        headers: [String: TemporalPayload] = [:],
        setRequestAttributes: (any Span) -> Void,
        setResponseAttributes: ((any Span, R) -> Void)? = nil,
        next: (_ headers: [String: TemporalPayload]) async throws -> R
    ) async throws -> R {
        let serviceContext = ServiceContext.current ?? .topLevel

        return try await self.tracer.withSpan(
            spanName,
            context: serviceContext,
            ofKind: .client
        ) { span in
            setRequestAttributes(span)

            // Inject context into tracer payload
            var tracerPayload = [String: String]()
            self.tracer.inject(serviceContext, into: &tracerPayload, using: self.injector)
            let convertedTracerPayload =
                try DataConverter
                .default
                .payloadConverter
                .convertValueHandlingVoid(tracerPayload)

            // Set encoded tracer payload as a header
            var headers = headers
            headers[self.tracingHeaderKey] = convertedTracerPayload

            let response: R
            do {
                response = try await next(headers)
            } catch {
                span.setStatus(SpanStatus(code: .error))
                throw error
            }

            setResponseAttributes?(span, response)
            return response
        }
    }

    // MARK: Inbound

    // Overload accepting async `next`.
    func recordInbound<R: Sendable>(
        spanName: String,
        headers: [String: TemporalPayload],
        setSpanAttributes: (any Span) -> Void,
        next: () async throws -> R
    ) async throws -> R {
        let serviceContext = try makeInboundServiceContext(headers: headers)

        return try await self.tracer.withSpan(
            spanName,
            context: serviceContext,
            ofKind: .server  // matches C#
        ) { span in
            setSpanAttributes(span)

            do {
                return try await next()
            } catch {
                span.setStatus(SpanStatus(code: .error))
                // we don't need to record the error here, this is automatically done by the `withSpan`
                throw error
            }
        }
    }

    // Overload accepting sync `next`.
    func recordInbound<R: Sendable>(
        spanName: String,
        headers: [String: TemporalPayload],
        setSpanAttributes: (any Span) -> Void,
        next: () throws -> R
    ) throws -> R {
        let serviceContext = try makeInboundServiceContext(headers: headers)

        return try self.tracer.withSpan(
            spanName,
            context: serviceContext,
            ofKind: .server  // matches C#
        ) { span in
            setSpanAttributes(span)

            do {
                return try next()
            } catch {
                span.setStatus(SpanStatus(code: .error))
                // we don't need to record the error here, this is automatically done by the `withSpan`
                throw error
            }
        }
    }

    /// Extracts raw Temporal tracing header into a new `ServiceContext`.
    private func makeInboundServiceContext(
        headers: [String: TemporalPayload]
    ) throws -> ServiceContext {
        var serviceContext = ServiceContext.topLevel

        // Check if header with tracer key exists
        guard let tracerPayload = headers[self.tracingHeaderKey] else {
            return serviceContext
        }

        // Like C#, use default sync payload converters and bubble up conversion errors
        let convertedTracerPayload: [String: String] =
            try DataConverter
            .default
            .payloadConverter
            .convertPayloadHandlingVoid(tracerPayload)

        // Set extracted tracer header as context.
        self.tracer.extract(
            convertedTracerPayload,
            into: &serviceContext,
            using: self.extractor
        )

        return serviceContext
    }
}
