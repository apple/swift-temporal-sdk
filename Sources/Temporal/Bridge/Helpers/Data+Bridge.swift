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

import Bridge
import Foundation

extension Data {
    /// Takes ownership of the buffer in `bytesPtr` and frees the `ByteArray`.
    init(byteArrayPointer: consuming UnsafePointer<TemporalCoreByteArray>) {
        let bytes = byteArrayPointer.pointee
        if let buf = UnsafeMutablePointer(mutating: bytes.data) {
            self = Data(bytesNoCopy: buf, count: bytes.cap, deallocator: .free)
        } else {
            self = Data()
        }

        byteArrayPointer.deallocate()
    }

    func withByteArrayRef<Return>(
        body: (TemporalCoreByteArrayRef) throws -> Return
    ) rethrows -> Return {
        try self.withUnsafeBytes { pointer in
            let buffer = pointer.bindMemory(to: UInt8.self)
            return try body(TemporalCoreByteArrayRef(data: buffer.baseAddress, size: buffer.count))
        }
    }
}

extension Array where Element == UInt8 {
    /// Pins the `[UInt8]` and calls `body` with its `ByteArrayRef`.
    func withByteArrayRef<T>(
        _ body: (TemporalCoreByteArrayRef) throws -> T
    ) rethrows -> T {
        return try self.withUnsafeBufferPointer { buf in
            let ref = TemporalCoreByteArrayRef(data: buf.baseAddress, size: buf.count)
            return try body(ref)
        }
    }
}
