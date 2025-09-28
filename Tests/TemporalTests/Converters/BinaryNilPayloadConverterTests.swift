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

import Temporal
import Testing

@Suite(.tags(.converterTests))
struct BinaryNilPayloadConverterTests {
    @Test
    func convertNil() async throws {
        let payloadConverter = BinaryNilPayloadConverter()

        let payload = try payloadConverter.convertValue(Optional<String>.none)
        #expect(payload.data == .init())
        #expect(payload.metadata == ["encoding": Array("binary/null".utf8)])

        let convertedNil = try payloadConverter.convertPayload(
            payload,
            as: Optional<String>.self
        )
        #expect(convertedNil == .none)
    }

    @Test
    func convertString() async throws {
        let payloadConverter = BinaryNilPayloadConverter()

        #expect(throws: Error.self) {
            try payloadConverter.convertValue("Foo")
        }

        #expect(throws: Error.self) {
            try payloadConverter.convertPayload(
                .init(data: .init(), metadata: [:]),
                as: String.self
            )
        }
    }
}
