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
    func encode(temporalFailure: TemporalFailure) async throws -> TemporalFailure {
        var temporalFailure = temporalFailure

        if let encodedAttributes = temporalFailure.encodedAttributes {
            temporalFailure.encodedAttributes = try await self.encode(payload: encodedAttributes)
        }

        switch temporalFailure.failureInfo {
        case .application(var application):
            var encodedDetails = [Api.Common.V1.Payload]()

            for detail in application.details {
                encodedDetails.append(try await self.encode(payload: detail))
            }

            application.details = encodedDetails
            temporalFailure.failureInfo = .application(application)

        case .cancelled(var cancelled):
            var encodedDetails = [Api.Common.V1.Payload]()

            for detail in cancelled.details {
                encodedDetails.append(try await self.encode(payload: detail))
            }

            cancelled.details = encodedDetails
            temporalFailure.failureInfo = .cancelled(cancelled)

        case .childWorkflowExecution, .terminated, .activity, .server:
            // No details so nothing to encode
            break

        case .timeout(var timeout):
            var encodedDetails = [Api.Common.V1.Payload]()

            for detail in timeout.lastHeartbeatDetails {
                encodedDetails.append(try await self.encode(payload: detail))
            }

            timeout.lastHeartbeatDetails = encodedDetails
            temporalFailure.failureInfo = .timeout(timeout)

        case nil:
            break

        case .some(.DO_NOT_EXHAUSTIVELY_MATCH_OVER_THIS_ENUM):
            fatalError("Used DO_NOT_EXHAUSTIVELY_MATCH_OVER_THIS_ENUM failure info")
        }

        if let cause = temporalFailure.cause {
            temporalFailure.cause = try await self.encode(temporalFailure: cause)
        }

        return temporalFailure
    }

    func decode(temporalFailure: TemporalFailure) async throws -> TemporalFailure {
        var temporalFailure = temporalFailure

        if let encodedAttributes = temporalFailure.encodedAttributes {
            temporalFailure.encodedAttributes = try await self.decode(payload: encodedAttributes)
        }

        switch temporalFailure.failureInfo {
        case .application(var application):
            var decodedDetails = [Api.Common.V1.Payload]()

            for detail in application.details {
                decodedDetails.append(try await self.decode(payload: detail))
            }

            application.details = decodedDetails
            temporalFailure.failureInfo = .application(application)

        case .cancelled(var cancelled):
            var decodedDetails = [Api.Common.V1.Payload]()

            for detail in cancelled.details {
                decodedDetails.append(try await self.decode(payload: detail))
            }

            cancelled.details = decodedDetails
            temporalFailure.failureInfo = .cancelled(cancelled)

        case .terminated(var terminated):
            var decodedDetails = [Api.Common.V1.Payload]()

            for detail in terminated.details {
                decodedDetails.append(try await self.decode(payload: detail))
            }

            terminated.details = decodedDetails
            temporalFailure.failureInfo = .terminated(terminated)

        case .timeout(var timeout):
            var decodedDetails = [Api.Common.V1.Payload]()

            for detail in timeout.lastHeartbeatDetails {
                decodedDetails.append(try await self.decode(payload: detail))
            }

            timeout.lastHeartbeatDetails = decodedDetails
            temporalFailure.failureInfo = .timeout(timeout)

        case .childWorkflowExecution, .activity, .server:
            // No details so nothing to decode
            break

        case nil:
            break

        case .some(.DO_NOT_EXHAUSTIVELY_MATCH_OVER_THIS_ENUM):
            fatalError("Used DO_NOT_EXHAUSTIVELY_MATCH_OVER_THIS_ENUM failure info")
        }

        if let cause = temporalFailure.cause {
            temporalFailure.cause = try await self.decode(temporalFailure: cause)
        }

        return temporalFailure
    }
}
