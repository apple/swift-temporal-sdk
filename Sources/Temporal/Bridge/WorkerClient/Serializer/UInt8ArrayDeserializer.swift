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

import GRPCCore

/// Deserializes the serialized bytes received from grpc-swift into `[UInt8]` array.
package struct UInt8ArrayDeserializer: GRPCCore.MessageDeserializer {
    @inlinable
    package func deserialize<Bytes: GRPCCore.GRPCContiguousBytes>(_ serializedMessageBytes: Bytes) throws -> [UInt8] {
        // creates `[UInt8]` copy of the underlying `GRPCContiguousBytes` to ensure contents remain valid
        serializedMessageBytes.withUnsafeBytes { Array($0) }
    }
}
