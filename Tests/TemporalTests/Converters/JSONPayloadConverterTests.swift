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
import Temporal
import Testing

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

@Suite(.tags(.converterTests))
struct JSONPayloadConverterTests {
    @Test
    func convertNil() async throws {
        let payloadConverter = JSONPayloadConverter()

        let payload = try payloadConverter.convertValue(Optional<String>.none)

        #expect(payload.data == Data([110, 117, 108, 108]))
        #expect(payload.metadata == ["encoding": Data("json/plain".utf8)])

        #expect(try payloadConverter.convertPayload(payload, as: Optional<String>.self) == nil)
    }

    @Test
    func convertArrayUInt8() async throws {
        let payloadConverter = JSONPayloadConverter()

        let payload = try payloadConverter.convertValue([UInt8]([1, 2, 3]))
        #expect(payload.data == Data([91, 49, 44, 50, 44, 51, 93]))
        #expect(payload.metadata == ["encoding": Data("json/plain".utf8)])

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
        #expect(payload.data == Data([34, 65, 81, 73, 68, 34]))
        #expect(payload.metadata == ["encoding": Data("json/plain".utf8)])

        let convertedData = try payloadConverter.convertPayload(
            payload,
            as: Data.self
        )
        #expect(convertedData == Data([1, 2, 3]))
    }

    @Test
    func convertDateKeepsFractionalSeconds() async throws {
        let payloadConverter = JSONPayloadConverter()
        let date = Date(timeIntervalSince1970: 1_737_302_400.25)

        let payload = try payloadConverter.convertValue(date)
        #expect(String(decoding: payload.data, as: UTF8.self) == "\"2025-01-19T16:00:00.250Z\"")

        let convertedDate = try payloadConverter.convertPayload(payload, as: Date.self)
        #expect(convertedDate == date)
    }

    @Test(arguments: [
        ("\"2025-01-19T16:00:00Z\"", 1_737_302_400.0),
        ("\"2025-01-19T16:00:00.250Z\"", 1_737_302_400.25),
        ("\"2025-01-19T16:00:00.250000+00:00\"", 1_737_302_400.25),
        ("\"2025-01-19T11:00:00-05:00\"", 1_737_302_400.0),
    ])
    func convertDateFromISO8601String(json: String, timeIntervalSince1970: Double) async throws {
        let payloadConverter = JSONPayloadConverter()
        let payload = Api.Common.V1.Payload.with {
            $0.metadata = ["encoding": Data("json/plain".utf8)]
            $0.data = Data(json.utf8)
        }

        let convertedDate = try payloadConverter.convertPayload(payload, as: Date.self)
        #expect(convertedDate == Date(timeIntervalSince1970: timeIntervalSince1970))
    }

    @Test
    func convertDateFromInvalidStringThrows() async throws {
        let payloadConverter = JSONPayloadConverter()
        let payload = Api.Common.V1.Payload.with {
            $0.metadata = ["encoding": Data("json/plain".utf8)]
            $0.data = Data("\"2025-01-19 16:00:00\"".utf8)
        }

        #expect(throws: (any Error).self) {
            try payloadConverter.convertPayload(payload, as: Date.self)
        }
    }

    @Test
    func convertString() async throws {
        let payloadConverter = JSONPayloadConverter()

        let payload = try payloadConverter.convertValue("Hello")
        #expect(payload.data == Data([34, 72, 101, 108, 108, 111, 34]))
        #expect(payload.metadata == ["encoding": Data("json/plain".utf8)])

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
            payload.data
                == Data([
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
                ])
        )
        #expect(payload.metadata == ["encoding": Data("json/plain".utf8)])

        let convertedData = try payloadConverter.convertPayload(
            payload,
            as: TestCodable.self
        )
        #expect(convertedData == testCodable)
    }
}
