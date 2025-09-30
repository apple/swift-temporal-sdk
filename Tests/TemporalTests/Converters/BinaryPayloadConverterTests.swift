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
struct BinaryPayloadConverterTests {
    @Test
    func convertNil() async throws {
        let payloadConverter = BinaryPayloadConverter()

        #expect(throws: Error.self) {
            try payloadConverter.convertValue(Optional<String>.none)
        }
    }

    @Test
    func convertArrayUInt8() async throws {
        let payloadConverter = BinaryPayloadConverter()

        let payload = try payloadConverter.convertValue([UInt8]([1, 2, 3]))
        #expect(payload.data == [1, 2, 3])
        #expect(payload.metadata == ["encoding": Array("binary/plain".utf8)])

        let convertedArray = try payloadConverter.convertPayload(
            payload,
            as: Array<UInt8>.self
        )
        #expect(convertedArray == [1, 2, 3])
    }

    @Test
    func convertOptionalArrayUInt8() async throws {
        let payloadConverter = BinaryPayloadConverter()

        let payload = try payloadConverter.convertValue(Optional.some([UInt8]([1, 2, 3])))
        #expect(payload.data == [1, 2, 3])
        #expect(payload.metadata == ["encoding": Array("binary/plain".utf8)])

        let convertedArray = try payloadConverter.convertPayload(
            payload,
            as: Array<UInt8>.self
        )
        #expect(convertedArray == [1, 2, 3])
    }

    @Test
    func convertData() async throws {
        let payloadConverter = BinaryPayloadConverter()

        let payload = try payloadConverter.convertValue(Data([1, 2, 3]))
        #expect(payload.data == [1, 2, 3])
        #expect(payload.metadata == ["encoding": Array("binary/plain".utf8)])

        let convertedData = try payloadConverter.convertPayload(
            payload,
            as: Data.self
        )
        #expect(convertedData == Data([1, 2, 3]))
    }
}
