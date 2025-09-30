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
import Metrics

/// Metrics context for instrumenting the `GRPCClient`.
struct GRPCMetricsContext {
    private let kind: ServiceKind
    private let startTime: ContinuousClock.Instant
    private let dimensions: [(String, String)]
    private let metricsFactory: MetricsFactory

    private let requestsPerRPC: Recorder
    private let responsesPerRPC: Recorder
    private let activeCalls: Meter

    init(kind: ServiceKind, dimensions: [(String, String)], metricsFactory: MetricsFactory) {
        self.kind = kind
        self.startTime = .now
        self.dimensions = dimensions
        self.metricsFactory = metricsFactory

        self.activeCalls = Meter(label: "rpc.\(kind.rawValue).active_requests", dimensions: dimensions, factory: metricsFactory)
        self.requestsPerRPC = Recorder(label: "rpc.\(kind.rawValue).requests_per_rpc", dimensions: dimensions, factory: metricsFactory)
        self.responsesPerRPC = Recorder(label: "rpc.\(kind.rawValue).responses_per_rpc", dimensions: dimensions, factory: metricsFactory)
    }

    func startCall() {
        activeCalls.increment()
    }

    func recordSentMessage() {
        switch kind {
        case .client:
            requestsPerRPC.record(1)
        case .server:
            responsesPerRPC.record(1)
        }
    }

    func recordReceivedMessage() {
        switch kind {
        case .client:
            responsesPerRPC.record(1)
        case .server:
            requestsPerRPC.record(1)
        }
    }

    func recordCallFinished(error: (any Error)?) {
        activeCalls.decrement()

        let statusCode: Status.Code = error?.rpcErrorCode.map { .init($0) } ?? .ok

        var dimensions = dimensions
        dimensions.append(attribute: \.rpc.gRPC.statusCode, .init(Int64(statusCode.rawValue)))

        Counter(label: "rpc.\(kind.rawValue).calls", dimensions: dimensions, factory: self.metricsFactory)
            .increment()

        Metrics.Timer(label: "rpc.\(kind.rawValue).duration", dimensions: dimensions, preferredDisplayUnit: .seconds, factory: self.metricsFactory)
            .record(duration: .now - startTime)

        switch kind {
        case .client:
            if statusCode != .ok {
                recordError(dimensions: dimensions)
            }
        case .server:
            switch statusCode {
            case .unknown, .deadlineExceeded, .unimplemented, .internalError, .unavailable, .dataLoss:
                recordError(dimensions: dimensions)
            default:
                break
            }
        }
    }

    private func recordError(dimensions: [(String, String)]) {
        Counter(label: "rpc.\(kind.rawValue).request.errors", dimensions: dimensions, factory: metricsFactory)
            .increment()
    }
}

extension Error {
    fileprivate var rpcErrorCode: RPCError.Code? {
        if let rpcError = self as? RPCError {
            return rpcError.code
        } else if let rpcError = self as? any RPCErrorConvertible {
            return rpcError.rpcErrorCode
        } else {
            return nil
        }
    }
}
