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

import SwiftProtobuf

/// The default failure converter.
///
/// This converter transforms any Swift error into a ``TemporalError``.
///
/// It also provides the option to encode the ``TemporalError/message`` and ``TemporalError/stackTrace``
/// into the ``Api/Failure/V1/Failure/encodedAttributes`` field.
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
    ) -> Api.Failure.V1.Failure {
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

    public func convertFailure(
        _ temporalFailure: Api.Failure.V1.Failure,
        payloadConverter: some PayloadConverter
    ) -> any Error {
        var temporalFailure = temporalFailure

        if temporalFailure.hasEncodedAttributes {
            do {
                let decodedAttributes = try payloadConverter.convertPayloadHandlingVoid(
                    temporalFailure.encodedAttributes,
                    as: [String: String].self
                )

                if let message = decodedAttributes["message"] {
                    temporalFailure.message = message
                }

                if let stackTrace = decodedAttributes["stackTrace"] {
                    temporalFailure.stackTrace = stackTrace
                }

                temporalFailure.encodedAttributes = .init()

            } catch {
                // Do nothing. C# SDK does the same
            }
        }

        var cause: (any Error)?
        if temporalFailure.hasCause {
            cause = self.convertFailure(
                temporalFailure.cause,
                payloadConverter: payloadConverter
            )
        }

        switch temporalFailure.failureInfo {
        case .applicationFailureInfo(let application):
            return ApplicationError(
                message: temporalFailure.message,
                cause: cause,
                stackTrace: temporalFailure.stackTrace,
                details: application.details.payloads,
                type: application.type,
                isNonRetryable: application.nonRetryable,
                nextRetryDelay: .init(protobufDuration: application.nextRetryDelay)
            )
        case .canceledFailureInfo(let cancelled):
            return CanceledError(
                message: temporalFailure.message,
                cause: cause,
                stackTrace: temporalFailure.stackTrace,
                details: cancelled.details.payloads
            )

        case .terminatedFailureInfo(_):
            return TerminatedError(
                message: temporalFailure.message,
                cause: cause,
                stackTrace: temporalFailure.stackTrace,
                details: []
            )

        case .childWorkflowExecutionFailureInfo(let childWorkflowExecution):
            return ChildWorkflowError(
                message: temporalFailure.message,
                cause: cause,
                stackTrace: temporalFailure.stackTrace,
                namespace: childWorkflowExecution.namespace,
                workflowID: childWorkflowExecution.workflowExecution.workflowID,
                runID: childWorkflowExecution.workflowExecution.runID,
                workflowName: childWorkflowExecution.workflowType.name,
                retryState: RetryState(retryState: childWorkflowExecution.retryState)
            )

        case .activityFailureInfo(let activity):
            return ActivityError(
                message: temporalFailure.message,
                cause: cause,
                stackTrace: temporalFailure.stackTrace,
                scheduledEventID: Int(activity.scheduledEventID),
                startedEventID: Int(activity.startedEventID),
                activityID: activity.activityID,
                activityType: activity.activityType.name,
                identity: activity.identity,
                retryState: RetryState(retryState: activity.retryState)
            )

        case .timeoutFailureInfo(let timeout):
            return TimeoutError(
                message: temporalFailure.message,
                type: TimeoutType(timeout.timeoutType),
                cause: cause,
                stackTrace: temporalFailure.stackTrace,
                lastHeartbeatDetails: timeout.lastHeartbeatDetails.payloads
            )
        case .serverFailureInfo(let server):
            return ServerError(
                message: temporalFailure.message,
                cause: cause,
                stackTrace: temporalFailure.stackTrace,
                isNonRetryable: server.nonRetryable
            )
        case .none, .resetWorkflowFailureInfo, .nexusOperationExecutionFailureInfo, .nexusHandlerFailureInfo:
            return BasicTemporalFailureError(
                message: temporalFailure.message,
                cause: cause,
                stackTrace: temporalFailure.stackTrace
            )
        }
    }

    private func convertTemporalFailureError(
        _ temporalFailureError: any TemporalFailureError,
        payloadConverter: some PayloadConverter
    ) -> Api.Failure.V1.Failure {
        var temporalFailure = Api.Failure.V1.Failure.with {
            $0.message = temporalFailureError.message
            $0.source = "swift-temporal-sdk"
            $0.stackTrace = temporalFailureError.stackTrace
        }

        if let cause = temporalFailureError.cause {
            temporalFailure.cause = self.convertError(
                cause,
                payloadConverter: payloadConverter
            )
        }

        switch temporalFailureError {
        case let applicationError as ApplicationError:
            temporalFailure.failureInfo = .applicationFailureInfo(
                .with {
                    if !applicationError.details.isEmpty {
                        $0.details = .with { $0.payloads = applicationError.details }
                    }
                    $0.type = applicationError.type ?? ""
                    $0.nonRetryable = applicationError.isNonRetryable
                    if let nextRetryDelay = applicationError.nextRetryDelay {
                        $0.nextRetryDelay = .init(duration: nextRetryDelay)
                    }
                }
            )
        case let cancelledError as CanceledError:
            temporalFailure.failureInfo = .canceledFailureInfo(
                .with { $0.details = .with { $0.payloads = cancelledError.details } }
            )

        case let terminatedError as TerminatedError:
            _ = terminatedError
            temporalFailure.failureInfo = .terminatedFailureInfo(.init())

        case let timeoutError as TimeoutError:
            temporalFailure.failureInfo = .timeoutFailureInfo(
                .with {
                    $0.timeoutType = .init(timeoutError.type)
                    $0.lastHeartbeatDetails = .with { $0.payloads = timeoutError.lastHeartbeatDetails }
                }
            )

        case let childWorkflowError as ChildWorkflowError:
            temporalFailure.failureInfo = .childWorkflowExecutionFailureInfo(
                .with {
                    $0.namespace = childWorkflowError.namespace
                    $0.workflowExecution = .with {
                        $0.workflowID = childWorkflowError.workflowID
                        $0.runID = childWorkflowError.runID
                    }
                    $0.workflowType = .with { $0.name = childWorkflowError.workflowName }
                    $0.retryState = .init(retryState: childWorkflowError.retryState)
                }
            )

        case let activityError as ActivityError:
            temporalFailure.failureInfo = .activityFailureInfo(
                .with {
                    $0.scheduledEventID = Int64(activityError.scheduledEventID)
                    $0.startedEventID = Int64(activityError.startedEventID)
                    $0.identity = activityError.identity
                    $0.activityType = .with { $0.name = activityError.activityType }
                    $0.activityID = activityError.activityID
                    $0.retryState = .init(retryState: activityError.retryState)
                }
            )

        default:
            temporalFailure.failureInfo = .applicationFailureInfo(.with { $0.type = "\(type(of: temporalFailureError))" })
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
