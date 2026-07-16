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
    ) throws(Failure) -> Return {
        var refs: [TemporalCoreByteArrayRef] = []
        refs.reserveCapacity(count)

        // Recurse pinning each string to `refs`, then hand it to `body`
        func iterate(iterator: inout Iterator) throws(Failure) -> Return {
            // All strings are pinned, call `body` with the assembled `refs`
            guard let buffer = iterator.next() else {
                return try refs.withUnsafeBufferPointer { refsBuffer throws(Failure) in
                    let refArray = TemporalCoreByteArrayRefArray(
                        data: refsBuffer.baseAddress,
                        size: refsBuffer.count
                    )
                    return try body(refArray)
                }
            }

            // Pin the string and recurse into the next one
            return try buffer.withByteArrayRef { ref throws(Failure) in
                refs.append(ref)
                return try iterate(iterator: &iterator)
            }
        }

        var iterator = makeIterator()
        return try iterate(iterator: &iterator)
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
