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
struct DataConverterTests {
    @Test
    func convertVoidValue() async throws {
        let dataConverter = DataConverter(
            payloadConverter: DefaultPayloadConverter(),
            failureConverter: DefaultFailureConverter(),
            payloadCodec: Base64PayloadCodec()
        )

        let payload = try await dataConverter.convertValue(())

        #expect(payload.data == Data())
        #expect(payload.metadata == [:])
    }

    @Test
    func convertValue() async throws {
        let dataConverter = DataConverter(
            payloadConverter: DefaultPayloadConverter(),
            failureConverter: DefaultFailureConverter(),
            payloadCodec: Base64PayloadCodec()
        )

        let payload = try await dataConverter.convertValue([UInt8]([1, 2, 3]))

        #expect(payload.data == Data([1, 2, 3]).base64EncodedData())
        #expect(payload.metadata["encoding"] == Data("binary/plain".utf8))
        #expect(payload.metadata["codec"] == Data("application/base64".utf8))
    }

    @Test
    func convertEmptyStringArrayValue() async throws {
        let dataConverter = DataConverter(
            payloadConverter: DefaultPayloadConverter(),
            failureConverter: DefaultFailureConverter(),
            payloadCodec: nil
        )

        let payload = try await dataConverter.convertValue([String]([]))

        #expect(payload.data == Data("[]".utf8))
        #expect(payload.metadata["encoding"] == Data("json/plain".utf8))
        #expect(payload.metadata["codec"] == nil)
    }

    @Test
    func convertValue_whenNoConverter() async throws {
        struct RandomStruct {}

        let dataConverter = DataConverter(
            payloadConverter: DefaultPayloadConverter(),
            failureConverter: DefaultFailureConverter(),
            payloadCodec: Base64PayloadCodec()
        )

        await #expect(throws: (any Error).self) {
            try await dataConverter.convertValue(RandomStruct())
        }
    }

    @Test
    func convertValue_whenPayloadingEncodingFails() async {
        let dataConverter = DataConverter(
            payloadConverter: DefaultPayloadConverter(),
            failureConverter: DefaultFailureConverter(),
            payloadCodec: FailingPayloadCodec()
        )

        await #expect(throws: CancellationError.self) {
            try await dataConverter.convertValue("Test")
        }
    }

    @Test
    func convertVoidPayloads() async throws {
        let dataConverter = DataConverter(
            payloadConverter: DefaultPayloadConverter(),
            failureConverter: DefaultFailureConverter(),
            payloadCodec: Base64PayloadCodec()
        )

        let payload = Api.Common.V1.Payload.with {
            $0.data = Data()
            $0.metadata = [:]
        }
        let void: Void? = try await dataConverter.convertPayloads([payload], as: Void.self) as Void

        #expect(void! == ())
    }

    @Test
    func convertPayloads() async throws {
        let dataConverter = DataConverter(
            payloadConverter: DefaultPayloadConverter(),
            failureConverter: DefaultFailureConverter(),
            payloadCodec: Base64PayloadCodec()
        )

        let payload = Api.Common.V1.Payload.with {
            $0.data = Data([1, 2, 3]).base64EncodedData()
            $0.metadata = [
                "codec": Data("application/base64".utf8),
                "encoding": Data("binary/plain".utf8),
            ]
        }
        let array = try await dataConverter.convertPayloads([payload], as: Array<UInt8>.self)

        #expect(array == Array([1, 2, 3]))
    }

    @Test
    func convertNil() async throws {
        let dataConverter = DataConverter(
            payloadConverter: DefaultPayloadConverter(),
            failureConverter: DefaultFailureConverter(),
            payloadCodec: Base64PayloadCodec()
        )

        let payload = Api.Common.V1.Payload.with {
            $0.data = Data()
            $0.metadata = ["encoding": Data("binary/null".utf8)]
        }

        let convertedNil = try await dataConverter.convertPayload(
            payload,
            as: Optional<String>.self
        )

        #expect(convertedNil == nil)
    }

    @Test
    func convertPayloads_whenNoConverter() async throws {
        let dataConverter = DataConverter(
            payloadConverter: DefaultPayloadConverter(),
            failureConverter: DefaultFailureConverter(),
            payloadCodec: Base64PayloadCodec()
        )

        await #expect(throws: (any Error).self) {
            try await dataConverter.convertPayloads(
                [
                    Api.Common.V1.Payload.with {
                        $0.data = Data()
                        $0.metadata = [:]
                    }
                ],
                as: Array<UInt8>.self
            )
        }
    }

    @Test
    func convertPayload_whenPayloadingDecodingFails() async {
        let dataConverter = DataConverter(
            payloadConverter: DefaultPayloadConverter(),
            failureConverter: DefaultFailureConverter(),
            payloadCodec: FailingPayloadCodec()
        )

        await #expect(throws: CancellationError.self) {
            try await dataConverter.convertPayloads(
                [
                    Api.Common.V1.Payload.with {
                        $0.data = Data()
                        $0.metadata = [:]
                    }
                ],
                as: Array<UInt8>.self
            )
        }
    }

    @Test
    func convertError() async throws {
        var failureConverter = DefaultFailureConverter()
        failureConverter.encodeCommonAttributes = true
        let dataConverter = DataConverter(
            payloadConverter: JSONPayloadConverter(),
            failureConverter: failureConverter,
            payloadCodec: Base64PayloadCodec()
        )

        let applicationError = ApplicationError(
            message: "Message",
            stackTrace: "StackTrace",
            details: [
                Api.Common.V1.Payload.with {
                    $0.data = Data("details".utf8)
                    $0.metadata = [:]
                }
            ],
            type: "TestError",
            isNonRetryable: false,
            nextRetryDelay: nil
        )

        let failure = await dataConverter.convertError(applicationError)

        #expect(failure.message == "Encoded failure")
        #expect(failure.source == "swift-temporal-sdk")
        #expect(failure.stackTrace == "")
        #expect(failure.encodedAttributes.data != Data())
        let expectedFailureInfo = Api.Failure.V1.Failure.OneOf_FailureInfo.applicationFailureInfo(
            .with {
                $0.details = .with {
                    $0.payloads = [
                        Api.Common.V1.Payload.with {
                            $0.data = Data("details".utf8).base64EncodedData()
                            $0.metadata = ["codec": Data("application/base64".utf8)]
                        }
                    ]
                }
                $0.type = "TestError"
                $0.nonRetryable = false
            }
        )
        #expect(failure.failureInfo == expectedFailureInfo)
    }

    @Test
    func convertError_whenPayloadingEncodingFails() async {
        var failureConverter = DefaultFailureConverter()
        failureConverter.encodeCommonAttributes = true
        let dataConverter = DataConverter(
            payloadConverter: JSONPayloadConverter(),
            failureConverter: failureConverter,
            payloadCodec: FailingPayloadCodec()
        )

        let convertedFailure = await dataConverter.convertError(TestError())
        let expectedFailure = Api.Failure.V1.Failure.with {
            $0.message = "Failed to encode failure"
            $0.source = "swift-temporal-sdk"
        }

        #expect(convertedFailure == expectedFailure)
    }

    @Test
    func convertFailure() async throws {
        let dataConverter = DataConverter.default

        let failure = Api.Failure.V1.Failure.with {
            $0.message = "Test message"
            $0.source = "swift-temporal-sdk"
        }
        let error = await dataConverter.convertFailure(failure)

        let basicTemporalFailureError = try #require(error as? BasicTemporalFailureError)
        #expect(basicTemporalFailureError.message == "Test message")
    }
}
