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

extension Duration {
    /// Total duration expressed in whole milliseconds.
    var milliseconds: UInt64 {
        let comps = self.components
        // Whole seconds → milliseconds
        let secondsInMs = UInt64(comps.seconds) * 1_000
        // Attoseconds → fractional milliseconds
        //   1 attosecond = 10⁻¹⁸ s
        //   1 ms         = 10⁻³ s = 10¹⁵ as
        let fractionalMs = UInt64(comps.attoseconds / 1_000_000_000_000_000)  // rounds down
        return secondsInMs + fractionalMs
    }
}
