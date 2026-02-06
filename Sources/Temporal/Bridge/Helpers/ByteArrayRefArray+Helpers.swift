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

extension Array where Element == String {
    func withByteArrayRefArray<Return, Failure: Error>(
        body: (TemporalCoreByteArrayRefArray) throws(Failure) -> Return
    ) rethrows -> Return {
        // Swift-managed [UInt8] buffer
        let buffers: [[UInt8]] = self.map { [UInt8]($0.utf8) }

        // Build the ByteArrayRef array
        let refs: [TemporalCoreByteArrayRef] = .init(unsafeUninitializedCapacity: buffers.count) { refBuffer, initializedCount in
            for i in 0..<buffers.count {
                // Capture pointer and length of each [UInt8]
                buffers[i].withUnsafeBufferPointer { bp in
                    refBuffer[i] = TemporalCoreByteArrayRef(data: bp.baseAddress!, size: bp.count)
                }
                initializedCount += 1
            }
        }

        // Memory valid for duration of body
        return try refs.withUnsafeBufferPointer { refBP throws(Failure) in
            let refArray = TemporalCoreByteArrayRefArray(
                data: refBP.baseAddress!,
                size: refBP.count
            )
            return try body(refArray)
        }
    }
}

extension TemporalCoreByteArrayRefArray {
    static var `nil`: TemporalCoreByteArrayRefArray {
        TemporalCoreByteArrayRefArray()
    }

    func toStringArray() -> [String] {
        guard let data = data else { return [] }
        let buffer = UnsafeBufferPointer(start: data, count: size)

        return buffer.map { String(byteArrayRef: $0) }
    }
}
