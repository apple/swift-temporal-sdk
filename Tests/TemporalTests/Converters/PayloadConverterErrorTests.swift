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
struct PayloadConverterErrorTests {
    @Test
    func binaryEncodeFailureNamesConverterAndType() throws {
        let converter = BinaryPayloadConverter()

        let error = #expect(throws: PayloadConverterError.self) {
            try converter.convertValue("not bytes")
        }
        let message = try #require(error).message
        #expect(message.contains("BinaryPayloadConverter"))
        #expect(message.contains("String"))
    }

    @Test
    func binaryDecodeFailureNamesRequestedType() throws {
        let converter = BinaryPayloadConverter()
        let payload = try converter.convertValue([UInt8]([1, 2, 3]))

        let error = #expect(throws: PayloadConverterError.self) {
            try converter.convertPayload(payload, as: String.self)
        }
        let message = try #require(error).message
        #expect(message.contains("BinaryPayloadConverter"))
        #expect(message.contains("String"))
    }

    @Test
    func binaryNilEncodeFailureIsDescriptive() throws {
        let converter = BinaryNilPayloadConverter()

        let error = #expect(throws: PayloadConverterError.self) {
            try converter.convertValue("not nil")
        }
        let message = try #require(error).message
        #expect(message.contains("BinaryNilPayloadConverter"))
        #expect(message.contains("nil optional"))
    }

    @Test
    func binaryProtobufEncodeFailureMentionsMessageProtocol() throws {
        let converter = BinaryProtobufPayloadConverter()

        let error = #expect(throws: PayloadConverterError.self) {
            try converter.convertValue("not a proto message")
        }
        let message = try #require(error).message
        #expect(message.contains("BinaryProtobufPayloadConverter"))
        #expect(message.contains("Message"))
    }

    @Test
    func compositeDecodeWithoutEncodingMetadataIsDescriptive() throws {
        let converter = CompositePayloadConverter(BinaryPayloadConverter())
        // A payload with no `encoding` metadata cannot be routed to a converter.
        let payload = Api.Common.V1.Payload.with { $0.data = Data([1, 2, 3]) }

        let error = #expect(throws: PayloadConverterError.self) {
            try converter.convertPayload(payload, as: [UInt8].self)
        }
        let message = try #require(error).message
        #expect(message.contains("CompositePayloadConverter"))
        #expect(message.contains("encoding"))
    }
}
