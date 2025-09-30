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
import Temporal
import Testing

@Suite(.tags(.converterTests))
struct CompositePayloadConverterTests {
    @Test
    func composesEncodingPayloadConverters() async throws {
        let binaryNilConverter = BinaryNilPayloadConverter()
        let binaryPlainConverter = BinaryPayloadConverter()
        let compositeConverter = CompositePayloadConverter(binaryNilConverter, binaryPlainConverter)

        let nilValue: String? = nil
        let expectedNilPayload = try binaryNilConverter.convertValue(nilValue)
        let nilPayload = try compositeConverter.convertValue(nilValue)
        #expect(nilPayload == expectedNilPayload)
        #expect(throws: Error.self) {
            try compositeConverter.convertPayload(nilPayload, as: String.self)
        }

        let arrayValue: [UInt8] = [1, 2, 3]
        let expectedBinaryPayload = try binaryPlainConverter.convertValue(arrayValue)
        let binaryPayload = try compositeConverter.convertValue(arrayValue)
        #expect(binaryPayload == expectedBinaryPayload)
        try #expect(compositeConverter.convertPayload(binaryPayload, as: [UInt8].self) == arrayValue)
    }

    private struct MockBinaryPayloadConverter: EncodingPayloadConverter {
        struct EncodingError: Error {}
        struct DecodingError: Error {}

        static let encoding = "binary/plain"

        func convertValue(_ value: some Any) throws -> TemporalPayload {
            return .init(data: [], metadata: ["encoding": Array(Self.encoding.utf8)])
        }

        func convertPayload<Value>(
            _ payload: TemporalPayload,
            as valueType: Value.Type
        ) throws -> Value {
            // Add a "watermark" to the payload to identify this converter and not the normal binary one decoded this
            let payloadData = payload.data + [0, 0]
            if valueType is [UInt8].Type {
                return (payloadData as! Value)
            } else if valueType is Data.Type {
                return Data(payloadData) as! Value
            }

            throw DecodingError()
        }
    }

    @Test
    func selectsFirstSuitablePayloadConverter() async throws {
        let realBinaryConverter = BinaryPayloadConverter()
        let converter = CompositePayloadConverter(MockBinaryPayloadConverter(), realBinaryConverter)
        let value: [UInt8] = [1, 2, 3]
        let payload = try converter.convertValue(value)
        #expect(payload.metadata == ["encoding": Array("binary/plain".utf8)])
        // The mock converter won't have actually converted the value
        #expect(payload.data == .init())

        let realPayload = try realBinaryConverter.convertValue(value)

        // The mock converter inserts the [0, 0] suffix
        try #expect(converter.convertPayload(realPayload, as: [UInt8].self) == [1, 2, 3, 0, 0])
    }
}
