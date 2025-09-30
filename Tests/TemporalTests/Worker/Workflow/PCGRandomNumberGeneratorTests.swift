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

import Temporal
import Testing

@Suite
struct PCGRandomNumberGeneratorTests {
    @Test
    func testDeterministic() {
        let seed = UInt64.random(in: .min...(.max))
        var generator1 = PCGRandomNumberGenerator(seed: seed)
        var generator2 = PCGRandomNumberGenerator(seed: seed)

        for _ in 0..<100000 {
            #expect(generator1.next() == generator2.next())
        }
    }
}
