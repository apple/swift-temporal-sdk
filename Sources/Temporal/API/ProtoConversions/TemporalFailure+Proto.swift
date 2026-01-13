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

extension Temporal_Api_Failure_V1_Failure {
    init(temporalFailure: TemporalFailure) {
        self = Self.with {
            $0.message = temporalFailure.message
            $0.source = temporalFailure.source
            $0.stackTrace = temporalFailure.stackTrace
            $0.encodedAttributes =
                temporalFailure.encodedAttributes
                .flatMap { .init(temporalPayload: $0) } ?? .init()
            $0.failureInfo = temporalFailure.failureInfo.flatMap { .init(failureInfo: $0) }
        }

        if let cause = temporalFailure.cause {
            self.cause = .init(temporalFailure: cause)
        }
    }
}

extension Temporal_Api_Failure_V1_Failure.OneOf_FailureInfo {
    init(failureInfo: TemporalFailure.FailureInfo) {
        switch failureInfo {
        case .application(let application):
            self = .applicationFailureInfo(.init(application: application))
        case .cancelled(let cancelled):
            self = .canceledFailureInfo(.init(cancelled: cancelled))
        case .terminated(let terminated):
            self = .terminatedFailureInfo(.init(terminated: terminated))
        case .childWorkflowExecution(let childWorkflowExecution):
            self = .childWorkflowExecutionFailureInfo(.init(childWorkflowExecution: childWorkflowExecution))
        case .activity(let activity):
            self = .activityFailureInfo(.init(activity: activity))
        case .timeout(let timeout):
            self = .timeoutFailureInfo(.init(timeout: timeout))
        case .server(let server):
            self = .serverFailureInfo(.init(server: server))
        case .DO_NOT_EXHAUSTIVELY_MATCH_OVER_THIS_ENUM:
            fatalError("Unexpected case DO_NOT_EXHAUSTIVELY_MATCH_OVER_THIS_ENUM")
        }
    }
}

extension Temporal_Api_Failure_V1_ApplicationFailureInfo {
    init(application: TemporalFailure.FailureInfo.Application) {
        self = .with {
            $0.type = application.type
            $0.nonRetryable = application.isNonRetryable
            if !application.details.isEmpty {
                $0.details = .with {
                    $0.payloads = application.details
                        .map { Temporal_Api_Common_V1_Payload(temporalPayload: $0) }
                }
            }
            if let nextRetryDelay = application.nextRetryDelay {
                $0.nextRetryDelay = Google_Protobuf_Duration(duration: nextRetryDelay)
            }
        }
    }
}

extension Temporal_Api_Failure_V1_CanceledFailureInfo {
    init(cancelled: TemporalFailure.FailureInfo.Cancelled) {
        self = .with {
            $0.details = .with {
                $0.payloads = cancelled.details
                    .map { Temporal_Api_Common_V1_Payload(temporalPayload: $0) }
            }
        }
    }
}

extension Temporal_Api_Failure_V1_TerminatedFailureInfo {
    init(terminated: TemporalFailure.FailureInfo.Terminated) {}
}

extension Temporal_Api_Failure_V1_ChildWorkflowExecutionFailureInfo {
    init(childWorkflowExecution: TemporalFailure.FailureInfo.ChildWorkflowExecution) {
        self = .with {
            $0.namespace = childWorkflowExecution.namespace
            $0.workflowType.name = childWorkflowExecution.workflowName
            $0.workflowExecution.runID = childWorkflowExecution.runID
            $0.workflowExecution.workflowID = childWorkflowExecution.workflowID
            $0.retryState = .init(retryState: childWorkflowExecution.retryState)
        }
    }
}

extension Temporal_Api_Failure_V1_ActivityFailureInfo {
    init(activity: TemporalFailure.FailureInfo.Activity) {
        self = .with {
            $0.scheduledEventID = Int64(activity.scheduledEventID)
            $0.startedEventID = Int64(activity.startedEventID)
            $0.identity = activity.identity
            $0.activityType.name = activity.activityType
            $0.activityID = activity.activityID
            $0.retryState = .init(retryState: activity.retryState)
        }
    }
}

extension Temporal_Api_Failure_V1_ServerFailureInfo {
    init(server: TemporalFailure.FailureInfo.Server) {
        self = .with {
            $0.nonRetryable = server.isNonRetryable
        }
    }
}

extension Temporal_Api_Failure_V1_TimeoutFailureInfo {
    init(timeout: TemporalFailure.FailureInfo.Timeout) {
        self = .with {
            $0.timeoutType = .init(timeout.type)
            $0.lastHeartbeatDetails = .with {
                $0.payloads = timeout.lastHeartbeatDetails
                    .map { Temporal_Api_Common_V1_Payload(temporalPayload: $0) }
            }
        }
    }
}

extension TemporalFailure {
    init(temporalAPIFailure: Temporal_Api_Failure_V1_Failure) {
        self.init(
            message: temporalAPIFailure.message,
            source: temporalAPIFailure.source,
            stackTrace: temporalAPIFailure.stackTrace,
            encodedAttributes: .init(temporalAPIPayload: temporalAPIFailure.encodedAttributes),
            failureInfo: temporalAPIFailure.failureInfo.flatMap { .init(temporalAPIFailureInfo: $0) }
        )

        if temporalAPIFailure.hasCause {
            self.cause = .init(temporalAPIFailure: temporalAPIFailure.cause)
        }
    }
}

extension TemporalFailure.FailureInfo {
    init(temporalAPIFailureInfo: Temporal_Api_Failure_V1_Failure.OneOf_FailureInfo) {
        switch temporalAPIFailureInfo {
        case .applicationFailureInfo(let applicationFailureInfo):
            self = .application(
                .init(
                    details: applicationFailureInfo.details.payloads.map { .init(temporalAPIPayload: $0) },
                    type: applicationFailureInfo.type,
                    isNonRetryable: applicationFailureInfo.nonRetryable,
                    nextRetryDelay: .init(protobufDuration: applicationFailureInfo.nextRetryDelay)
                )
            )
        case .canceledFailureInfo(let canceledFailureInfo):
            self = .cancelled(
                .init(
                    details: canceledFailureInfo.details.payloads.map { .init(temporalAPIPayload: $0) }
                )
            )
        case .childWorkflowExecutionFailureInfo(let childWorkflowExecutionFailureInfo):
            self = .childWorkflowExecution(
                .init(
                    namespace: childWorkflowExecutionFailureInfo.namespace,
                    workflowID: childWorkflowExecutionFailureInfo.workflowExecution.workflowID,
                    runID: childWorkflowExecutionFailureInfo.workflowExecution.runID,
                    workflowName: childWorkflowExecutionFailureInfo.workflowType.name,
                    retryState: .init(retryState: childWorkflowExecutionFailureInfo.retryState)
                )
            )
        case .activityFailureInfo(let activityFailureInfo):
            self = .activity(
                .init(
                    scheduledEventID: Int(activityFailureInfo.scheduledEventID),
                    startedEventID: Int(activityFailureInfo.startedEventID),
                    identity: activityFailureInfo.identity,
                    activityType: activityFailureInfo.activityType.name,
                    activityID: activityFailureInfo.activityID,
                    retryState: .init(retryState: activityFailureInfo.retryState)
                )
            )
        case .timeoutFailureInfo(let timeoutInfo):
            self = .timeout(
                .init(
                    type: {
                        let timeoutType: TimeoutType =
                            switch timeoutInfo.timeoutType {
                            case .startToClose: .startToClose
                            case .scheduleToStart: .scheduleToStart
                            case .scheduleToClose: .scheduleToClose
                            case .heartbeat: .heartbeat
                            case .unspecified, .UNRECOGNIZED: .unspecified
                            }

                        return timeoutType
                    }(),
                    lastHeartbeatDetails: timeoutInfo.lastHeartbeatDetails.payloads.map { .init(temporalAPIPayload: $0) }
                )
            )
        case .terminatedFailureInfo:
            self = .terminated(.init())
        case let .serverFailureInfo(failureInfo):
            self = .server(.init(isNonRetryable: failureInfo.nonRetryable))
        case .resetWorkflowFailureInfo:
            // TODO: Add support
            fatalError("Unsupported failure info")
        case .nexusOperationExecutionFailureInfo:
            // TODO: Add support
            fatalError("Unsupported failure info")
        case .nexusHandlerFailureInfo:
            // TODO: Add support
            fatalError("Unsupported failure info")
        }
    }
}
