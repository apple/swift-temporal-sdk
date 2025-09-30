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

#if canImport(FoundationEssentials)
import struct FoundationEssentials.UUID
#else
import struct Foundation.UUID
#endif

#if compiler(<6.3)  // Swift main nightly not tagged 6.3 yet, so this guard does nothing (for now)
extension UUID {
    @_disfavoredOverload  // Method was upstreamed into FoundationPreview 6.3: https://github.com/swiftlang/swift-foundation/pull/1271
    package static func random(
        using generator: inout some RandomNumberGenerator
    ) -> UUID {
        let first = UInt64.random(in: .min ... .max, using: &generator)
        let second = UInt64.random(in: .min ... .max, using: &generator)

        var firstBits = first
        var secondBits = second

        // Set the version to 4 (0100 in binary)
        firstBits &= 0xFFFF_FFFF_FFFF_0FFF  // Clear the last 12 bits
        firstBits |= 0x0000_0000_0000_4000  // Set the version bits to '0100' at the correct position

        // Set the variant to '10' (RFC9562 variant)
        secondBits &= 0x3FFF_FFFF_FFFF_FFFF  // Clear the 2 most significant bits
        secondBits |= 0x8000_0000_0000_0000  // Set the two MSB to '10'

        let uuidBytes = (
            UInt8(truncatingIfNeeded: firstBits >> 56),
            UInt8(truncatingIfNeeded: firstBits >> 48),
            UInt8(truncatingIfNeeded: firstBits >> 40),
            UInt8(truncatingIfNeeded: firstBits >> 32),
            UInt8(truncatingIfNeeded: firstBits >> 24),
            UInt8(truncatingIfNeeded: firstBits >> 16),
            UInt8(truncatingIfNeeded: firstBits >> 8),
            UInt8(truncatingIfNeeded: firstBits),
            UInt8(truncatingIfNeeded: secondBits >> 56),
            UInt8(truncatingIfNeeded: secondBits >> 48),
            UInt8(truncatingIfNeeded: secondBits >> 40),
            UInt8(truncatingIfNeeded: secondBits >> 32),
            UInt8(truncatingIfNeeded: secondBits >> 24),
            UInt8(truncatingIfNeeded: secondBits >> 16),
            UInt8(truncatingIfNeeded: secondBits >> 8),
            UInt8(truncatingIfNeeded: secondBits)
        )

        return UUID(uuid: uuidBytes)
    }
}
#endif
