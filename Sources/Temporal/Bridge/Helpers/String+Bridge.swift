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

import Bridge

extension String {
    init(byteArrayRef bytes: TemporalCoreByteArrayRef) {
        self = String(unsafeUninitializedCapacity: bytes.size) { buffer in
            let buf = UnsafeBufferPointer<UInt8>(start: bytes.data, count: bytes.size)
            let (_, index) = buffer.initialize(from: buf)
            return index
        }
    }

    init(byteArray: TemporalCoreByteArray) {
        self = String(unsafeUninitializedCapacity: byteArray.size) { buffer in
            let buf = UnsafeBufferPointer<UInt8>(start: byteArray.data, count: byteArray.size)
            let (_, index) = buffer.initialize(from: buf)
            return index
        }
    }

    func withByteArrayRef<Return, Failure: Error>(
        body: (TemporalCoreByteArrayRef) throws(Failure) -> Return
    ) throws(Failure) -> Return {
        try self.utf8CString.withUnsafeBufferPointer { buffer throws(Failure) -> Return in
            try buffer.withMemoryRebound(to: UInt8.self) { buffer throws(Failure) -> Return in
                // Don't include the null terminator in the size
                try body(TemporalCoreByteArrayRef(data: buffer.baseAddress, size: buffer.count - 1))
            }
        }
    }
}
