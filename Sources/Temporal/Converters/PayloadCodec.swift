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

/// A payload codec transforms an array of ``Api/Common/V1/Payload`` into another ``Api/Common/V1/Payload`` array.
///
/// An example use is compressing or encrypting your workflow execution data.
///
/// - Important: Payload codecs are allowed to be asynchronous and non-deterministic and are applied outside of workflows.
public protocol PayloadCodec: Sendable {
    /// Encode the payload.
    ///
    /// - Parameter payload: The input payload, e.g. the output of a workflow or an activity.
    /// - Returns: The encoded payload e.g. the compressed or encrypted version of the input payload.
    func encode(payload: Api.Common.V1.Payload) async throws -> Api.Common.V1.Payload

    /// Decodes the payload.
    ///
    /// - Parameter payload: The input payload, e.g. the input to a workflow or activity.
    /// - Returns: The decoded payload, e.g. the uncompressed or decrypted payload.
    func decode(payload: Api.Common.V1.Payload) async throws -> Api.Common.V1.Payload
}

extension PayloadCodec {
    func encode(failure: Api.Failure.V1.Failure) async throws -> Api.Failure.V1.Failure {
        var failure = failure

        if failure.hasEncodedAttributes {
            failure.encodedAttributes = try await self.encode(payload: failure.encodedAttributes)
        }

        switch failure.failureInfo {
        case .applicationFailureInfo(var application):
            var encodedPayloads = [Api.Common.V1.Payload]()
            for payload in application.details.payloads {
                encodedPayloads.append(try await self.encode(payload: payload))
            }
            application.details.payloads = encodedPayloads
            failure.failureInfo = .applicationFailureInfo(application)

        case .canceledFailureInfo(var cancelled):
            var encodedPayloads = [Api.Common.V1.Payload]()
            for payload in cancelled.details.payloads {
                encodedPayloads.append(try await self.encode(payload: payload))
            }
            cancelled.details.payloads = encodedPayloads
            failure.failureInfo = .canceledFailureInfo(cancelled)

        case .timeoutFailureInfo(var timeout):
            var encodedPayloads = [Api.Common.V1.Payload]()
            for payload in timeout.lastHeartbeatDetails.payloads {
                encodedPayloads.append(try await self.encode(payload: payload))
            }
            timeout.lastHeartbeatDetails.payloads = encodedPayloads
            failure.failureInfo = .timeoutFailureInfo(timeout)

        case .terminatedFailureInfo, .childWorkflowExecutionFailureInfo, .activityFailureInfo,
            .serverFailureInfo, .resetWorkflowFailureInfo, .nexusOperationExecutionFailureInfo,
            .nexusHandlerFailureInfo:
            // No payload details to encode
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
            var decodedPayloads = [Api.Common.V1.Payload]()
            for payload in application.details.payloads {
                decodedPayloads.append(try await self.decode(payload: payload))
            }
            application.details.payloads = decodedPayloads
            failure.failureInfo = .applicationFailureInfo(application)

        case .canceledFailureInfo(var cancelled):
            var decodedPayloads = [Api.Common.V1.Payload]()
            for payload in cancelled.details.payloads {
                decodedPayloads.append(try await self.decode(payload: payload))
            }
            cancelled.details.payloads = decodedPayloads
            failure.failureInfo = .canceledFailureInfo(cancelled)

        case .terminatedFailureInfo:
            // TerminatedFailureInfo has no payload details in the proto
            break

        case .timeoutFailureInfo(var timeout):
            var decodedPayloads = [Api.Common.V1.Payload]()
            for payload in timeout.lastHeartbeatDetails.payloads {
                decodedPayloads.append(try await self.decode(payload: payload))
            }
            timeout.lastHeartbeatDetails.payloads = decodedPayloads
            failure.failureInfo = .timeoutFailureInfo(timeout)

        case .childWorkflowExecutionFailureInfo, .activityFailureInfo, .serverFailureInfo,
            .resetWorkflowFailureInfo, .nexusOperationExecutionFailureInfo, .nexusHandlerFailureInfo:
            // No payload details to decode
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
