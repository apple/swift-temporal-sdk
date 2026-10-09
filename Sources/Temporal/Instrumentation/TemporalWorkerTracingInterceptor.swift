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
    /// The name of the Temporal tracing header key.
    private var tracingHeaderKey: String

    /// Creates a tracing interceptor using the globally configured instrumentation system tracer.
    ///
    /// - Parameter tracingHeaderKey: The name of the Temporal tracing header key, defaults to `_tracer-data`.
    public init(tracingHeaderKey: String = "_tracer-data") {
        self.tracingHeaderKey = tracingHeaderKey
    }

    public var workflowInboundInterceptor: WorkflowInbound? {
        Self.WorkflowInbound(tracingHeaderKey: self.tracingHeaderKey)
    }

    public var workflowOutboundInterceptor: WorkflowOutbound? {
        Self.WorkflowOutbound(tracingHeaderKey: self.tracingHeaderKey)
    }

    public var activityInboundInterceptor: ActivityInbound? {
        Self.ActivityInbound(tracingHeaderKey: self.tracingHeaderKey)
    }

    // no activity outbound interceptor as it's only a heartbeat and C# SDK also doesn't intercept these calls
}
