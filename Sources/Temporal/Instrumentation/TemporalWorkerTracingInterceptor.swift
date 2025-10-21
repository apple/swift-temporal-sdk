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

/// Interceptor that creates and propagates distributed tracing activities for Temporal worker operations.
///
/// ### Usage
///
/// Install the interceptor on your ``TemporalWorker`` configuration to enable automatic tracing:
///
/// ```swift
/// let worker = TemporalWorker(
///     configuration: .init(
///         interceptors: [TemporalWorkerTracingInterceptor()]
///     )
/// )
/// ```
///
/// For optimal diagnostic coverage, position this interceptor as the final entry in your interceptor chain to capture
/// the complete request lifecycle including modifications from other interceptors.
///
/// The interceptor leverages `swift-distributed-tracing` `ServiceContext` for context propagation and serializes
/// diagnostic activities through Temporal headers for cross-system observability.
///
/// - Important: Requires `swift-distributed-tracing` instrumentation system to be properly configured in your application.
///
/// - Note: For comprehensive tracing coverage, ensure this interceptor is the last in your interceptor chain.
public struct TemporalWorkerTracingInterceptor: WorkerInterceptor {
    /// `Injector` injecting the context into the Temporal request headers.
    private let injector: TemporalHeaderInjector = .init()
    /// `Extractor` extracting the context from the Temporal response headers.
    private let extractor: TemporalHeaderExtractor = .init()
    /// `Tracer` that creates the new trace spans.
    private let tracer: any Tracer
    /// The name of the Temporal tracing header key.
    private var tracingHeaderKey: String

    /// Creates a tracing interceptor using the globally configured instrumentation system tracer.
    ///
    /// - Parameter tracingHeaderKey: The name of the Temporal tracing header key, defaults to `_tracer-data`.
    /// - Important: Ensure `InstrumentationSystem` is properly bootstrapped before using this initializer.
    public init(tracingHeaderKey: String = "_tracer-data") {
        self.init(
            tracer: InstrumentationSystem.tracer,
            tracingHeaderKey: tracingHeaderKey
        )
    }

    /// Create the interceptor with a custom `Tracer`, useful for testing.
    ///
    /// - Parameters:
    ///    - tracer: Custom `Tracer` passed in.
    ///    - tracingHeaderKey: The name of the Temporal tracing header key, defaults to `_tracer-data`.
    package init(
        tracer: any Tracer,
        tracingHeaderKey: String = "_tracer-data"
    ) {
        self.tracer = tracer
        self.tracingHeaderKey = tracingHeaderKey
    }

    public func makeWorkflowInboundInterceptor() -> WorkflowInbound? {
        Self.WorkflowInbound(tracer: self.tracer, tracingHeaderKey: self.tracingHeaderKey)
    }

    public func makeWorkflowOutboundInterceptor() -> WorkflowOutbound? {
        Self.WorkflowOutbound(tracer: self.tracer, tracingHeaderKey: self.tracingHeaderKey)
    }

    public func makeActivityInboundInterceptor() -> ActivityInbound? {
        Self.ActivityInbound(tracer: self.tracer, tracingHeaderKey: self.tracingHeaderKey)
    }

    // no activity outbound interceptor as it's only a heartbeat and C# SDK also doesn't intercept these calls
}
