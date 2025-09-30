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

import AsyncAlgorithms
import Temporal
import Testing

@Suite
struct FlattenedAsyncSequenceTests {
    @Test
    func someCollections() async {
        let result = await Array(
            [[1], [2, 3], [4, 5, 6]]
                .async
                .flattened()
        )

        #expect(result == [1, 2, 3, 4, 5, 6])
    }

    @Test
    func emptyCollection() async {
        let result = await [Int](
            [[], [], []]
                .async
                .flattened()
        )

        #expect(result == [])
    }

    @Test
    func partialEmptyCollection() async {
        let result = await [Int](
            [[], [1], [], [2, 3]]
                .async
                .flattened()
        )

        #expect(result == [1, 2, 3])
    }
}
