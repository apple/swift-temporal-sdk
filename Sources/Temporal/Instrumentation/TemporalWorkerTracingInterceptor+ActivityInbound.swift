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

extension TemporalWorkerTracingInterceptor {
    /// Activity inbound interceptor that instruments all worker inbound activity requests with distributed tracing.
    public struct ActivityInbound: ActivityInboundInterceptor {
        private let traceRecording: TemporalTraceRecording

        /// Create the worker activity inbound interceptor.
        ///
        /// - Parameters:
        ///    - tracer: The `Tracer` instance to use for creating spans.
        ///    - tracingHeaderKey: The name of the Temporal tracing header key.
        package init(tracer: any Tracer, tracingHeaderKey: String) {
            self.traceRecording = TemporalTraceRecording(
                tracer: tracer,
                tracingHeaderKey: tracingHeaderKey
            )
        }

        public func executeActivity<Activity>(
            input: ExecuteActivityInput<Activity>,
            next: (ExecuteActivityInput<Activity>) async throws -> Activity.Output
        ) async throws -> Activity.Output {
            try await self.traceRecording.recordInbound(
                spanName: "RunActivity:\(Activity.name)",
                headers: input.headers,
                setSpanAttributes: { span in
                    span.setWorkerExecuteActivitySpanAttributes(info: input)
                },
                next: {
                    try await next(input)
                }
            )
        }
    }
}
