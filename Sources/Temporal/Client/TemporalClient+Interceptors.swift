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

import GRPCCore
import GRPCOTelTracingInterceptors
import Logging
import TemporalInstrumentation

// MARK: Temporal Interceptors

extension TemporalClient {
    package struct Interceptor: InterceptorImplementation, Sendable {
        package let workflowService: WorkflowService
        let interceptors: [any ClientOutboundInterceptor]
    }
}

// MARK: GRPC Interceptors

extension TemporalClient {
    static func grpcClientInterceptors(serverHostname: String, logger: Logger) -> [any GRPCCore.ClientInterceptor] {
        [
            ClientOTelTracingInterceptor(
                serverHostname: serverHostname,
                networkTransportMethod: "tcp",
                traceEachMessage: true,
                includeRequestMetadata: true,
                includeResponseMetadata: true
            ),
            ClientOTelMetricsInterceptor(
                serverHostname: serverHostname,
                networkTransportMethod: .tcp
            ),
            ClientOTelLoggingInterceptor(
                logger: logger,
                serviceName: "swift-temporal-sdk.TemporalClient",
                serverHostname: serverHostname,
                networkTransportMethod: .tcp,
                serviceVersion: Constants.sdkVersion,
                includeRequestMetadata: true,
                includeResponseMetadata: true
            ),
        ]
    }
}
