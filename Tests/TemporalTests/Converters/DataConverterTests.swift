//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Temporal SDK open source project
//
// Copyright (c) 2025 Apple Inc. and the Swift Temporal SDK project authors
// Licensed under MIT License
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Swift Cassandra Client project authors
//
// SPDX-License-Identifier: MIT
//
//===----------------------------------------------------------------------===//

import Foundation
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

        #expect(payload.data == Array(Data()))
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

        #expect(payload.data == Array(Data([1, 2, 3]).base64EncodedData()))
        #expect(payload.metadata["encoding"] == Array("binary/plain".utf8))
        #expect(payload.metadata["codec"] == Array("application/base64".utf8))
    }

    @Test
    func convertEmptyStringArrayValue() async throws {
        let dataConverter = DataConverter(
            payloadConverter: DefaultPayloadConverter(),
            failureConverter: DefaultFailureConverter(),
            payloadCodec: nil
        )

        let payload = try await dataConverter.convertValue([String]([]))

        #expect(payload.data == Array("[]".utf8))
        #expect(payload.metadata["encoding"] == Array("json/plain".utf8))
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

        await #expect(throws: Error.self) {
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

    #if compiler(>=6.2)
    @Test
    func convertVoidPayloads() async throws {
        let dataConverter = DataConverter(
            payloadConverter: DefaultPayloadConverter(),
            failureConverter: DefaultFailureConverter(),
            payloadCodec: Base64PayloadCodec()
        )

        let payload = TemporalPayload(
            data: Array(Data()),
            metadata: [:]
        )
        let void: Void? = try await dataConverter.convertPayloads([payload], as: Void.self) as Void

        #expect(void! == ())
    }
    #endif

    @Test
    func convertPayloads() async throws {
        let dataConverter = DataConverter(
            payloadConverter: DefaultPayloadConverter(),
            failureConverter: DefaultFailureConverter(),
            payloadCodec: Base64PayloadCodec()
        )

        let payload = TemporalPayload(
            data: Array(Data([1, 2, 3]).base64EncodedData()),
            metadata: [
                "codec": Array("application/base64".utf8),
                "encoding": Array("binary/plain".utf8),
            ]
        )
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

        let payload = TemporalPayload(data: .init(), metadata: ["encoding": Array("binary/null".utf8)])

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

        await #expect(throws: Error.self) {
            try await dataConverter.convertPayloads(
                [TemporalPayload(data: [], metadata: [:])],
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
                [TemporalPayload(data: [], metadata: [:])],
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
                .init(data: Array("details".utf8), metadata: [:])
            ],
            type: "TestError",
            isNonRetryable: false,
            nextRetryDelay: nil
        )

        let temporalFailure = await dataConverter.convertError(applicationError)

        #expect(temporalFailure.message == "Encoded failure")
        #expect(temporalFailure.source == "swift-temporal-sdk")
        #expect(temporalFailure.stackTrace == "")
        #expect(temporalFailure.encodedAttributes?.data != nil)
        let expectedFailureInfo = TemporalFailure.FailureInfo.application(
            .init(
                details: [
                    .init(
                        data: Array(Data("details".utf8).base64EncodedData()),
                        metadata: ["codec": Array("application/base64".utf8)]
                    )
                ],
                type: "TestError",
                isNonRetryable: false,
                nextRetryDelay: nil
            )
        )
        #expect(temporalFailure.failureInfo == expectedFailureInfo)
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
        let expectedFailure = TemporalFailure(
            message: "Failed to encode failure",
            source: "swift-temporal-sdk",
            stackTrace: ""
        )

        #expect(convertedFailure == expectedFailure)
    }

    @Test
    func convertTemporalFailure() async throws {
        let dataConverter = DataConverter.default

        let temporalFailure = TemporalFailure(
            message: "Test message",
            source: "swift-temporal-sdk",
            stackTrace: ""
        )
        let error = await dataConverter.convertTemporalFailure(temporalFailure)

        let basicTemporalFailureError = try #require(error as? BasicTemporalFailureError)
        #expect(basicTemporalFailureError.message == "Test message")
    }
}
