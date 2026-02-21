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
struct BinaryNilPayloadConverterTests {
    @Test
    func convertNil() async throws {
        let payloadConverter = BinaryNilPayloadConverter()

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
    func convertString() async throws {
        let payloadConverter = BinaryNilPayloadConverter()

        #expect(throws: (any Error).self) {
            try payloadConverter.convertValue("Foo")
        }

        #expect(throws: (any Error).self) {
            try payloadConverter.convertPayload(
                Api.Common.V1.Payload.with {
                    $0.data = .init()
                    $0.metadata = [:]
                },
                as: String.self
            )
        }
    }
}
