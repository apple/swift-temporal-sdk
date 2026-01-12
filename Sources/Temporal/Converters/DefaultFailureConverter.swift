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

/// The default failure converter.
///
/// This converter transforms any Swift error into a ``TemporalError``.
///
/// It also provides the option to encode the ``TemporalError/message`` and ``TemporalError/stackTrace``
/// into the ``TemporalFailure/encodedAttributes`` field.
/// This behavior is configured via the ``DefaultFailureConverter/encodeCommonAttributes`` property.
public struct DefaultFailureConverter: FailureConverter {
    /// Indicates wether the common attributes should be encoded.
    ///
    /// When set to `true` then the `message` and `stackTrace` fields are converted and encoded using the payload converter.
    public var encodeCommonAttributes: Bool = false

    /// Initializes a new default failure converter.
    public init() {}

    public func convertError(
        _ error: any Error,
        payloadConverter: some PayloadConverter
    ) -> TemporalFailure {
        // Use as TemporalFailureError if it already is one,
        // otherwise create a new one as an application failure
        let temporalFailureError = error as? any TemporalFailureError ?? ApplicationError(error: error)

        var temporalFailure = self.convertTemporalFailureError(
            temporalFailureError,
            payloadConverter: payloadConverter
        )

        // If encoding of attributes is enabled we need to do this.
        if self.encodeCommonAttributes {
            // This is documented here: https://docs.temporal.io/dataconversion#failure-converter
            let attributes: [String: String] = [
                "message": temporalFailure.message,
                "stackTrace": temporalFailure.stackTrace,
            ]

            // This string matches what the other SDKs do
            temporalFailure.message = "Encoded failure"
            temporalFailure.stackTrace = ""

            do {
                temporalFailure.encodedAttributes = try payloadConverter.convertValueHandlingVoid(attributes)
            } catch {
                temporalFailure.message = "Failed to encode common attributes \(error)"
            }
        }

        return temporalFailure
    }

    public func convertTemporalFailure(
        _ temporalFailure: TemporalFailure,
        payloadConverter: some PayloadConverter
    ) -> any Error {
        var temporalFailure = temporalFailure

        if let encodedAttributes = temporalFailure.encodedAttributes {
            do {
                let decodedAttributes = try payloadConverter.convertPayloadHandlingVoid(
                    encodedAttributes,
                    as: [String: String].self
                )

                if let message = decodedAttributes["message"] {
                    temporalFailure.message = message
                }

                if let stackTrace = decodedAttributes["stackTrace"] {
                    temporalFailure.stackTrace = stackTrace
                }

                temporalFailure.encodedAttributes = nil

            } catch {
                // Do nothing. C# SDK does the same
            }
        }

        var cause: (any Error)?
        if let causeTemporalFailure = temporalFailure.cause {
            cause = self.convertTemporalFailure(
                causeTemporalFailure,
                payloadConverter: payloadConverter
            )
        }

        switch temporalFailure.failureInfo {
        case .application(let application):
            return ApplicationError(
                message: temporalFailure.message,
                cause: cause,
                stackTrace: temporalFailure.stackTrace,
                details: application.details,
                type: application.type,
                isNonRetryable: application.isNonRetryable,
                nextRetryDelay: application.nextRetryDelay
            )
        case .cancelled(let cancelled):
            return CanceledError(
                message: temporalFailure.message,
                cause: cause,
                stackTrace: temporalFailure.stackTrace,
                details: cancelled.details
            )

        case .terminated(let terminated):
            return TerminatedError(
                message: temporalFailure.message,
                cause: cause,
                stackTrace: temporalFailure.stackTrace,
                details: terminated.details
            )

        case .childWorkflowExecution(let childWorkflowExecution):
            return ChildWorkflowError(
                message: temporalFailure.message,
                cause: cause,
                stackTrace: temporalFailure.stackTrace,
                namespace: childWorkflowExecution.namespace,
                workflowID: childWorkflowExecution.workflowID,
                runID: childWorkflowExecution.runID,
                workflowName: childWorkflowExecution.workflowName,
                retryState: childWorkflowExecution.retryState
            )

        case .activity(let activity):
            return ActivityError(
                message: temporalFailure.message,
                cause: cause,
                stackTrace: temporalFailure.stackTrace,
                scheduledEventID: activity.scheduledEventID,
                startedEventID: activity.startedEventID,
                activityID: activity.activityID,
                activityType: activity.activityType,
                identity: activity.identity,
                retryState: activity.retryState
            )

        case .timeout(let timeout):
            return TimeoutError(
                message: temporalFailure.message,
                type: timeout.type,
                cause: cause,
                stackTrace: temporalFailure.stackTrace,
                lastHeartbeatDetails: timeout.lastHeartbeatDetails
            )
        case .server(let server):
            return ServerError(
                message: temporalFailure.message,
                cause: cause,
                stackTrace: temporalFailure.stackTrace,
                isNonRetryable: server.isNonRetryable
            )
        case .none:
            return BasicTemporalFailureError(
                message: temporalFailure.message,
                cause: cause,
                stackTrace: temporalFailure.stackTrace
            )

        case .DO_NOT_EXHAUSTIVELY_MATCH_OVER_THIS_ENUM:
            fatalError("Unexpected case DO_NOT_EXHAUSTIVELY_MATCH_OVER_THIS_ENUM")
        }
    }

    private func convertTemporalFailureError(
        _ temporalFailureError: any TemporalFailureError,
        payloadConverter: some PayloadConverter
    ) -> TemporalFailure {
        var temporalFailure = TemporalFailure(
            message: temporalFailureError.message,
            source: "swift-temporal-sdk",
            stackTrace: temporalFailureError.stackTrace
        )

        if let cause = temporalFailureError.cause {
            temporalFailure.cause = self.convertError(
                cause,
                payloadConverter: payloadConverter
            )
        }

        switch temporalFailureError {
        case let applicationError as ApplicationError:
            temporalFailure.failureInfo = .application(
                .init(
                    details: applicationError.details,
                    type: applicationError.type ?? "",
                    isNonRetryable: applicationError.isNonRetryable,
                    nextRetryDelay: applicationError.nextRetryDelay
                )
            )
        case let cancelledError as CanceledError:
            temporalFailure.failureInfo = .cancelled(.init(details: cancelledError.details))

        case let terminatedError as TerminatedError:
            temporalFailure.failureInfo = .terminated(.init(details: terminatedError.details))

        case let timeoutError as TimeoutError:
            temporalFailure.failureInfo = .timeout(.init(type: timeoutError.type, lastHeartbeatDetails: timeoutError.lastHeartbeatDetails))

        case let childWorkflowError as ChildWorkflowError:
            temporalFailure.failureInfo = .childWorkflowExecution(
                .init(
                    namespace: childWorkflowError.namespace,
                    workflowID: childWorkflowError.workflowID,
                    runID: childWorkflowError.runID,
                    workflowName: childWorkflowError.workflowName,
                    retryState: childWorkflowError.retryState
                )
            )

        case let activityError as ActivityError:
            temporalFailure.failureInfo = .activity(
                .init(
                    scheduledEventID: activityError.scheduledEventID,
                    startedEventID: activityError.startedEventID,
                    identity: activityError.identity,
                    activityType: activityError.activityType,
                    activityID: activityError.activityID,
                    retryState: activityError.retryState
                )
            )

        default:
            temporalFailure.failureInfo = .application(.init(type: "\(type(of: temporalFailureError))"))
        }
        return temporalFailure
    }
}

extension ApplicationError {
    fileprivate init(error: any Error) {
        self.init(
            message: "\(error)",
            cause: nil,
            details: [],
            type: "\(Swift.type(of: error))",
            isNonRetryable: false
        )
    }
}
