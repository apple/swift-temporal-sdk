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

import Foundation
import SwiftProtobuf
import Temporal
import Testing

@Suite(.tags(.converterTests))
struct DefaultFailureConverterTests {
    private struct TestError: Error, CustomStringConvertible {
        let description: String
    }

    @Test
    func encodeRandomError() async throws {
        let testError = TestError(description: "Error description")
        let failureConverter = DefaultFailureConverter()
        let jsonPayloadConverter = JSONPayloadConverter()

        let temporalFailure = failureConverter.convertError(
            testError,
            payloadConverter: jsonPayloadConverter
        )

        #expect(temporalFailure.message == "Error description")
        let expectedFailureInfo = TemporalFailure.FailureInfo.application(
            .init(
                type: "TestError"
            )
        )
        #expect(temporalFailure.failureInfo == expectedFailureInfo)
    }

    @Test
    func decodeApplicationFailure() async throws {
        let applicationError = ApplicationError(
            message: "Test message",
            stackTrace: "",
            type: "TestError",
            isNonRetryable: true,
            nextRetryDelay: .seconds(1)
        )

        let failureConverter = DefaultFailureConverter()
        let jsonPayloadConverter = JSONPayloadConverter()

        let temporalFailure = failureConverter.convertError(
            applicationError,
            payloadConverter: jsonPayloadConverter
        )

        let error = failureConverter.convertTemporalFailure(
            temporalFailure,
            payloadConverter: jsonPayloadConverter
        )

        let convertedApplicationError = try #require(error as? ApplicationError)
        #expect(convertedApplicationError.message == applicationError.message)
        #expect(convertedApplicationError.stackTrace == applicationError.stackTrace)
        #expect(convertedApplicationError.type == applicationError.type)
        #expect(convertedApplicationError.isNonRetryable == applicationError.isNonRetryable)
        #expect(convertedApplicationError.nextRetryDelay == applicationError.nextRetryDelay)
    }

    @Test
    func applicationErrorWithCauseRoundTrips() async throws {
        let applicationError = ApplicationError(
            message: "Test message",
            cause: CanceledError(message: "My cancelled message"),
            stackTrace: "",
            type: "TestError",
            isNonRetryable: true,
            nextRetryDelay: .seconds(1)
        )

        let failureConverter = DefaultFailureConverter()
        let jsonPayloadConverter = JSONPayloadConverter()

        let temporalFailure = failureConverter.convertError(
            applicationError,
            payloadConverter: jsonPayloadConverter
        )

        let error = failureConverter.convertTemporalFailure(
            temporalFailure,
            payloadConverter: jsonPayloadConverter
        )

        let convertedApplicationError = try #require(error as? ApplicationError)
        #expect(convertedApplicationError.message == applicationError.message)
        #expect(convertedApplicationError.stackTrace == applicationError.stackTrace)
        #expect(convertedApplicationError.type == applicationError.type)
        #expect(convertedApplicationError.isNonRetryable == applicationError.isNonRetryable)
        #expect(convertedApplicationError.nextRetryDelay == applicationError.nextRetryDelay)
        let convertedCanceledError = try #require(convertedApplicationError.cause as? CanceledError)
        #expect(convertedCanceledError.message == "My cancelled message")
    }

    @Test
    func encodeCommonAttributes() async throws {
        let testError = TestError(description: "Error description")
        var failureConverter = DefaultFailureConverter()
        failureConverter.encodeCommonAttributes = true
        let jsonEncoder = JSONEncoder()
        jsonEncoder.outputFormatting = .sortedKeys
        let jsonPayloadConverter = JSONPayloadConverter(jsonEncoder: jsonEncoder)

        let temporalFailure = failureConverter.convertError(
            testError,
            payloadConverter: jsonPayloadConverter
        )

        #expect(temporalFailure.message == "Encoded failure")
        #expect(temporalFailure.stackTrace == "")
        let expectedPayload = try jsonPayloadConverter.convertValue([
            "message": "Error description",
            "stackTrace": "",
        ])
        #expect(temporalFailure.encodedAttributes == expectedPayload)
        let expectedFailureInfo = TemporalFailure.FailureInfo.application(
            .init(
                type: "TestError"
            )
        )
        #expect(temporalFailure.failureInfo == expectedFailureInfo)
    }

    @Test
    func decodeCommonAttributes() async throws {
        let failureConverter = DefaultFailureConverter()
        let jsonPayloadConverter = JSONPayloadConverter()
        let encodedAttributes = try jsonPayloadConverter.convertValue([
            "message": "Error description",
            "stackTrace": "Some stack trace",
        ])

        let temporalFailure = TemporalFailure(
            message: "Encoded failure",
            source: "swift-temporal-sdk",
            stackTrace: "",
            encodedAttributes: encodedAttributes
        )

        let error = failureConverter.convertTemporalFailure(
            temporalFailure,
            payloadConverter: jsonPayloadConverter
        )

        let basicTemporalFailureError = try #require(error as? BasicTemporalFailureError)
        #expect(basicTemporalFailureError.message == "Error description")
        #expect(basicTemporalFailureError.stackTrace == "Some stack trace")

    }

    @Test
    func temporalFailureWithApplicationInfo() async throws {
        let detail1 = "detail 1"
        let detail2 = "detail 2"
        let temporalFailure = TemporalFailure(
            message: "My Error",
            source: "swift-temporal-sdk",
            stackTrace: "Some stack trace",
            failureInfo: .application(
                .init(
                    details: [
                        Api.Common.V1.Payload.with { $0.data = Data(detail1.utf8) },
                        Api.Common.V1.Payload.with { $0.data = Data(detail2.utf8) },
                    ],
                    type: "MyErrorType",
                    isNonRetryable: true
                )
            )
        )
        let failureConverter = DefaultFailureConverter()
        let jsonPayloadConverter = JSONPayloadConverter()

        let error = failureConverter.convertTemporalFailure(
            temporalFailure,
            payloadConverter: jsonPayloadConverter
        )

        let decodedError = try #require(error as? ApplicationError)
        let expectedDetails = [
            Api.Common.V1.Payload.with { $0.data = Data(detail1.utf8) },
            Api.Common.V1.Payload.with { $0.data = Data(detail2.utf8) },
        ]
        #expect(decodedError.message == "My Error")
        #expect(decodedError.stackTrace == "Some stack trace")
        #expect(decodedError.isNonRetryable == true)
        #expect(decodedError.type == "MyErrorType")
        #expect(decodedError.details == expectedDetails)
    }

    @Test
    func temporalFailureWithCanceledInfo() async throws {
        let detail1 = "detail 1"
        let detail2 = "detail 2"
        let temporalFailure = TemporalFailure(
            message: "My Error",
            source: "swift-temporal-sdk",
            stackTrace: "Some stack trace",
            failureInfo: .cancelled(
                .init(
                    details: [
                        Api.Common.V1.Payload.with { $0.data = Data(detail1.utf8) },
                        Api.Common.V1.Payload.with { $0.data = Data(detail2.utf8) },
                    ]
                )
            )
        )
        let failureConverter = DefaultFailureConverter()
        let jsonPayloadConverter = JSONPayloadConverter()

        let error = failureConverter.convertTemporalFailure(
            temporalFailure,
            payloadConverter: jsonPayloadConverter
        )

        let decodedError = try #require(error as? CanceledError)
        let expectedDetails = [
            Api.Common.V1.Payload.with { $0.data = Data(detail1.utf8) },
            Api.Common.V1.Payload.with { $0.data = Data(detail2.utf8) },
        ]
        #expect(decodedError.message == "My Error")
        #expect(decodedError.stackTrace == "Some stack trace")
        #expect(decodedError.details == expectedDetails)
    }

    @Test
    func temporalFailureWithCancelledInfoAndCancelledCause() async throws {
        let detail1 = "detail 1"
        let detail2 = "detail 2"
        let temporalFailure = TemporalFailure(
            message: "My Error",
            source: "swift-temporal-sdk",
            stackTrace: "Some stack trace",
            cause: .init(
                message: "My inner error",
                source: "swift-temporal-sdk",
                stackTrace: "Some inner stack trace",
                failureInfo: .cancelled(.init())
            ),
            failureInfo: .cancelled(
                .init(
                    details: [
                        Api.Common.V1.Payload.with { $0.data = Data(detail1.utf8) },
                        Api.Common.V1.Payload.with { $0.data = Data(detail2.utf8) },
                    ]
                )
            )
        )
        let failureConverter = DefaultFailureConverter()
        let jsonPayloadConverter = JSONPayloadConverter()

        let error = failureConverter.convertTemporalFailure(
            temporalFailure,
            payloadConverter: jsonPayloadConverter
        )

        let decodedError = try #require(error as? CanceledError)
        let expectedDetails = [
            Api.Common.V1.Payload.with { $0.data = Data(detail1.utf8) },
            Api.Common.V1.Payload.with { $0.data = Data(detail2.utf8) },
        ]
        #expect(decodedError.message == "My Error")
        #expect(decodedError.stackTrace == "Some stack trace")
        #expect(decodedError.details == expectedDetails)
        let innerDecodedError = try #require(decodedError.cause as? CanceledError)
        #expect(innerDecodedError.message == "My inner error")
        #expect(innerDecodedError.stackTrace == "Some inner stack trace")
    }

    @Test
    func childWorkflowExecutionFailure() async throws {
        let error = ChildWorkflowError(
            message: "Child workflow failed",
            stackTrace: "",
            namespace: "namespace",
            workflowID: "workflow-id",
            runID: "rund-id",
            workflowName: "workflow-name",
            retryState: .inProgress
        )

        let temporalFailure = await DataConverter.default.convertError(error)
        let convertedError = await DataConverter.default.convertTemporalFailure(temporalFailure)
        let convertedChildWorkflowError = try #require(convertedError as? ChildWorkflowError)
        #expect(convertedChildWorkflowError.message == error.message)
        #expect(convertedChildWorkflowError.stackTrace == error.stackTrace)
        #expect(convertedChildWorkflowError.namespace == error.namespace)
        #expect(convertedChildWorkflowError.workflowID == error.workflowID)
        #expect(convertedChildWorkflowError.runID == error.runID)
        #expect(convertedChildWorkflowError.workflowName == error.workflowName)
        #expect(convertedChildWorkflowError.retryState == error.retryState)
    }

    @Test
    func temporalFailureWithTimeoutInfo() async throws {
        let detail1 = "detail 1"
        let detail2 = "detail 2"
        let temporalFailure = TemporalFailure(
            message: "My Error",
            source: "swift-temporal-sdk",
            stackTrace: "Some stack trace",
            failureInfo: .timeout(
                .init(
                    type: .startToClose,
                    lastHeartbeatDetails: [
                        Api.Common.V1.Payload.with { $0.data = Data(detail1.utf8) },
                        Api.Common.V1.Payload.with { $0.data = Data(detail2.utf8) },
                    ]
                )
            )
        )
        let failureConverter = DefaultFailureConverter()
        let jsonPayloadConverter = JSONPayloadConverter()

        let error = failureConverter.convertTemporalFailure(
            temporalFailure,
            payloadConverter: jsonPayloadConverter
        )

        let decodedError = try #require(error as? TimeoutError)
        let expectedDetails = [
            Api.Common.V1.Payload.with {
                $0.data = Data(detail1.utf8)
                $0.metadata = [:]
            },
            Api.Common.V1.Payload.with {
                $0.data = Data(detail2.utf8)
                $0.metadata = [:]
            },
        ]
        #expect(decodedError.message == "My Error")
        #expect(decodedError.stackTrace == "Some stack trace")
        #expect(decodedError.type == .startToClose)
        #expect(decodedError.lastHeartbeatDetails == expectedDetails)
    }
}
