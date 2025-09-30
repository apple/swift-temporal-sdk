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
struct BinaryProtobufPayloadConverterTests {
    @Test
    func convertNil() async throws {
        let payloadConverter = BinaryProtobufPayloadConverter()

        #expect(throws: Error.self) {
            try payloadConverter.convertValue(Optional<String>.none)
        }
    }

    @Test
    func convertArrayUInt8() async throws {
        let payloadConverter = BinaryProtobufPayloadConverter()

        #expect(throws: Error.self) {
            try payloadConverter.convertValue([UInt8]([1, 2, 3]))
        }
    }

    @Test
    func convertProtoMessage() async throws {
        let payloadConverter = BinaryProtobufPayloadConverter()
        let testMessage = TestMessage.with {
            $0.seconds = 1
        }

        let payload = try payloadConverter.convertValue(testMessage)
        #expect(payload.data == [8, 1])
        #expect(payload.metadata == ["encoding": Array("binary/protobuf".utf8)])

        let convertedMessage = try payloadConverter.convertPayload(
            payload,
            as: TestMessage.self
        )
        #expect(convertedMessage.seconds == 1)
    }
}
