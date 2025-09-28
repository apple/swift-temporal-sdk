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

import struct Foundation.UUID

@Suite
struct UUIDRandomTests {
    @Test
    func versionAndVariant() {
        var generator = SystemRandomNumberGenerator()
        for _ in 0..<10000 {
            let uuid = UUID.random(using: &generator)
            #expect(uuid.versionNumber == 0b0100)
            #expect(uuid.varint == 0b10)
        }
    }
}

extension UUID {
    var versionNumber: Int {
        Int(self.uuid.6 >> 4)
    }

    var varint: Int {
        Int(self.uuid.8 >> 6 & 0b11)
    }
}
