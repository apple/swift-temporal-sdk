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

/// A payload codec transforms payloads into other payloads.
///
/// An example use is compressing or encrypting your workflow execution data.
///
/// - Important: Payload codecs are allowed to be asynchronous and non-deterministic and are applied outside of workflows.
public protocol PayloadCodec: Sendable {
    /// Encode the given payloads into a new set of payloads.
    ///
    /// - Parameter payloads: The input payloads to encode.
    /// - Returns: The encoded payloads. Note: this does not have to be the same number as
    /// payloads given, but it must be at least one and cannot be more than was given.
    func encode(payloads: some Collection<Api.Common.V1.Payload>) async throws -> [Api.Common.V1.Payload]

    /// Decode the given payloads into a new set of payloads.
    ///
    /// - Parameter payloads: The input payloads to decode.
    /// - Returns: The decoded payloads. Note: this does not have to be the same number as
    /// payloads given, but it must be at least one and cannot be more than was given.
    func decode(payloads: some Collection<Api.Common.V1.Payload>) async throws -> [Api.Common.V1.Payload]
}

extension PayloadCodec {
    /// Encode a single payload.
    ///
    /// - Parameter payload: The input payload.
    /// - Returns: The encoded payload.
    public func encode(payload: Api.Common.V1.Payload) async throws -> Api.Common.V1.Payload {
        try await self.encode(payloads: CollectionOfOne(payload))[0]
    }

    /// Decode a single payload.
    ///
    /// - Parameter payload: The input payload.
    /// - Returns: The decoded payload.
    public func decode(payload: Api.Common.V1.Payload) async throws -> Api.Common.V1.Payload {
        try await self.decode(payloads: CollectionOfOne(payload))[0]
    }
}

extension PayloadCodec {
    func encode(failure: Api.Failure.V1.Failure) async throws -> Api.Failure.V1.Failure {
        var failure = failure

        if failure.hasEncodedAttributes {
            failure.encodedAttributes = try await self.encode(payload: failure.encodedAttributes)
        }

        switch failure.failureInfo {
        case .applicationFailureInfo(var application):
            application.details.payloads = try await self.encode(payloads: application.details.payloads)
            failure.failureInfo = .applicationFailureInfo(application)

        case .canceledFailureInfo(var cancelled):
            cancelled.details.payloads = try await self.encode(payloads: cancelled.details.payloads)
            failure.failureInfo = .canceledFailureInfo(cancelled)

        case .timeoutFailureInfo(var timeout):
            timeout.lastHeartbeatDetails.payloads = try await self.encode(
                payloads: timeout.lastHeartbeatDetails.payloads
            )
            failure.failureInfo = .timeoutFailureInfo(timeout)

        case .resetWorkflowFailureInfo(var resetWorkflow):
            resetWorkflow.lastHeartbeatDetails.payloads = try await self.encode(
                payloads: resetWorkflow.lastHeartbeatDetails.payloads
            )
            failure.failureInfo = .resetWorkflowFailureInfo(resetWorkflow)

        case .terminatedFailureInfo, .childWorkflowExecutionFailureInfo, .activityFailureInfo,
            .serverFailureInfo, .nexusOperationExecutionFailureInfo,
            .nexusHandlerFailureInfo:
            break

        case .none:
            break
        }

        if failure.hasCause {
            failure.cause = try await self.encode(failure: failure.cause)
        }

        return failure
    }

    func decode(failure: Api.Failure.V1.Failure) async throws -> Api.Failure.V1.Failure {
        var failure = failure

        if failure.hasEncodedAttributes {
            failure.encodedAttributes = try await self.decode(payload: failure.encodedAttributes)
        }

        switch failure.failureInfo {
        case .applicationFailureInfo(var application):
            application.details.payloads = try await self.decode(payloads: application.details.payloads)
            failure.failureInfo = .applicationFailureInfo(application)

        case .canceledFailureInfo(var cancelled):
            cancelled.details.payloads = try await self.decode(payloads: cancelled.details.payloads)
            failure.failureInfo = .canceledFailureInfo(cancelled)

        case .terminatedFailureInfo:
            break

        case .timeoutFailureInfo(var timeout):
            timeout.lastHeartbeatDetails.payloads = try await self.decode(
                payloads: timeout.lastHeartbeatDetails.payloads
            )
            failure.failureInfo = .timeoutFailureInfo(timeout)

        case .resetWorkflowFailureInfo(var resetWorkflow):
            resetWorkflow.lastHeartbeatDetails.payloads = try await self.decode(
                payloads: resetWorkflow.lastHeartbeatDetails.payloads
            )
            failure.failureInfo = .resetWorkflowFailureInfo(resetWorkflow)

        case .childWorkflowExecutionFailureInfo, .activityFailureInfo, .serverFailureInfo,
            .nexusOperationExecutionFailureInfo, .nexusHandlerFailureInfo:
            break

        case .none:
            break
        }

        if failure.hasCause {
            failure.cause = try await self.decode(failure: failure.cause)
        }

        return failure
    }
}
