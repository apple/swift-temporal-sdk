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
struct DefaultPayloadConverterTests {
    private struct TestMessage: Message, _MessageImplementationBase, _ProtoNameProviding, Sendable {
        var seconds: Int64 = 0

        var unknownFields = UnknownStorage()

        init() {}

        static let protoMessageName: String = "TestMessage"
        static let _protobuf_nameMap = _NameMap(bytecode: "\0\u{1}seconds\0")

        mutating func decodeMessage<D: Decoder>(decoder: inout D) throws {
            while let fieldNumber = try decoder.nextFieldNumber() {
                switch fieldNumber {
                case 1: try { try decoder.decodeSingularInt64Field(value: &self.seconds) }()
                default: break
                }
            }
        }

        func traverse<V: Visitor>(visitor: inout V) throws {
            if self.seconds != 0 {
                try visitor.visitSingularInt64Field(value: self.seconds, fieldNumber: 1)
            }
            try unknownFields.traverse(visitor: &visitor)
        }

        static func == (lhs: TestMessage, rhs: TestMessage) -> Bool {
            if lhs.seconds != rhs.seconds { return false }
            if lhs.unknownFields != rhs.unknownFields { return false }
            return true
        }
    }

    @Test
    func convertNil() async throws {
        let payloadConverter = DefaultPayloadConverter()

        let payload = try payloadConverter.convertValue(Optional<String>.none)
        #expect(payload.data == .init())
        #expect(payload.metadata == ["encoding": Data("binary/null".utf8)])

        let convertedNil = try payloadConverter.convertPayload(
            payload,
            as: Optional<String>.self
        )
        #expect(convertedNil == .none)
    }

    @Test
    func convertArrayUInt8() async throws {
        let payloadConverter = DefaultPayloadConverter()

        let payload = try payloadConverter.convertValue([UInt8]([1, 2, 3]))
        #expect(payload.data == Data([1, 2, 3]))
        #expect(payload.metadata == ["encoding": Data("binary/plain".utf8)])

        let convertedArray = try payloadConverter.convertPayload(
            payload,
            as: Array<UInt8>.self
        )
        #expect(convertedArray == [1, 2, 3])
    }

    @Test
    func convertData() async throws {
        let payloadConverter = DefaultPayloadConverter()

        let payload = try payloadConverter.convertValue(Data([1, 2, 3]))
        #expect(payload.data == Data([1, 2, 3]))
        #expect(payload.metadata == ["encoding": Data("binary/plain".utf8)])

        let convertedData = try payloadConverter.convertPayload(
            payload,
            as: Data.self
        )
        #expect(convertedData == Data([1, 2, 3]))
    }

    @Test
    func convertProtoMessage() async throws {
        let payloadConverter = JSONProtobufPayloadConverter()
        let testMessage = TestMessage.with {
            $0.seconds = 1
        }

        let payload = try payloadConverter.convertValue(testMessage)
        #expect(payload.data == Data([123, 34, 115, 101, 99, 111, 110, 100, 115, 34, 58, 34, 49, 34, 125]))
        #expect(payload.metadata == ["encoding": Data("json/protobuf".utf8)])

        let convertedMessage = try payloadConverter.convertPayload(
            payload,
            as: TestMessage.self
        )
        #expect(convertedMessage.seconds == 1)
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
