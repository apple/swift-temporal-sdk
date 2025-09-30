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

/// A seeded deterministic random number generator.
package struct PCGRandomNumberGenerator: RandomNumberGenerator {
    private static let multiplier: UInt128 = 47_026_247_687_942_121_848_144_207_491_837_523_525
    private static let increment: UInt128 = 117_397_592_171_526_113_268_558_934_119_004_209_487

    private var state: UInt128

    package init(seed: UInt64) {
        self.state = UInt128(seed)
    }

    // Implements pcg_oneseq_128_xsl_rr_64_random_r from https://www.pcg-random.org
    package mutating func next() -> UInt64 {
        self.state = self.state &* Self.multiplier &+ Self.increment

        return rotr64(
            value: UInt64(truncatingIfNeeded: self.state &>> 64) ^ UInt64(truncatingIfNeeded: self.state),
            rotation: UInt64(truncatingIfNeeded: self.state &>> 122)
        )
    }

    private func rotr64(value: UInt64, rotation: UInt64) -> UInt64 {
        (value &>> rotation) | value &<< ((~rotation &+ 1) & 63)
    }
}
