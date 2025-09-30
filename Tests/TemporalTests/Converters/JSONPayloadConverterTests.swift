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
struct JSONPayloadConverterTests {
    @Test
    func convertNil() async throws {
        let payloadConverter = JSONPayloadConverter()

        let payload = try payloadConverter.convertValue(Optional<String>.none)

        #expect(payload.data == [110, 117, 108, 108])
        #expect(payload.metadata == ["encoding": Array("json/plain".utf8)])

        #expect(try payloadConverter.convertPayload(payload, as: Optional<String>.self) == nil)
    }

    @Test
    func convertArrayUInt8() async throws {
        let payloadConverter = JSONPayloadConverter()

        let payload = try payloadConverter.convertValue([UInt8]([1, 2, 3]))
        #expect(payload.data == [91, 49, 44, 50, 44, 51, 93])
        #expect(payload.metadata == ["encoding": Array("json/plain".utf8)])

        let convertedArray = try payloadConverter.convertPayload(
            payload,
            as: Array<UInt8>.self
        )
        #expect(convertedArray == [1, 2, 3])
    }

    @Test
    func convertData() async throws {
        let payloadConverter = JSONPayloadConverter()

        let payload = try payloadConverter.convertValue(Data([1, 2, 3]))
        #expect(payload.data == [34, 65, 81, 73, 68, 34])
        #expect(payload.metadata == ["encoding": Array("json/plain".utf8)])

        let convertedData = try payloadConverter.convertPayload(
            payload,
            as: Data.self
        )
        #expect(convertedData == Data([1, 2, 3]))
    }

    @Test
    func convertString() async throws {
        let payloadConverter = JSONPayloadConverter()

        let payload = try payloadConverter.convertValue("Hello")
        #expect(payload.data == [34, 72, 101, 108, 108, 111, 34])
        #expect(payload.metadata == ["encoding": Array("json/plain".utf8)])

        let convertedData = try payloadConverter.convertPayload(
            payload,
            as: String.self
        )
        #expect(convertedData == "Hello")
    }

    @Test
    func convertCodable() async throws {
        let jsonEncoder = JSONEncoder()
        jsonEncoder.outputFormatting = .sortedKeys
        let payloadConverter = JSONPayloadConverter(jsonEncoder: jsonEncoder)
        let testCodable = TestCodable(
            someString: "Hello",
            someInt: 1234,
            someBool: true,
            someData: Data([1, 2, 3, 4])
        )

        let payload = try payloadConverter.convertValue(testCodable)
        #expect(
            payload.data == [
                123, 34, 115, 111,
                109, 101, 66, 111,
                111, 108, 34, 58,
                116, 114, 117, 101,
                44, 34, 115, 111,
                109, 101, 68, 97,
                116, 97, 34, 58,
                34, 65, 81, 73,
                68, 66, 65, 61,
                61, 34, 44, 34,
                115, 111, 109, 101,
                73, 110, 116, 34,
                58, 49, 50, 51,
                52, 44, 34, 115,
                111, 109, 101, 83,
                116, 114, 105, 110,
                103, 34, 58, 34,
                72, 101, 108, 108,
                111, 34, 125,
            ]
        )
        #expect(payload.metadata == ["encoding": Array("json/plain".utf8)])

        let convertedData = try payloadConverter.convertPayload(
            payload,
            as: TestCodable.self
        )
        #expect(convertedData == testCodable)
    }
}
