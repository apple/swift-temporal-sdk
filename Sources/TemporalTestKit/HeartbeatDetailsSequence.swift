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

/// An async sequence of heartbeat details emitted by an activity.
public struct HeartbeatDetailsSequence: AsyncSequence {
    /// Iterator implementation for an heartbeat details async sequence.
    public struct AsyncIterator: AsyncIteratorProtocol {
        private var base: AsyncStream<[any Sendable]>.AsyncIterator

        fileprivate init(base: AsyncStream<[any Sendable]>.AsyncIterator) {
            self.base = base
        }

        public mutating func next(isolation actor: isolated (any Actor)?) async -> [any Sendable]? {
            await base.next(isolation: actor)
        }
    }

    private let base: AsyncStream<[any Sendable]>

    init(base: AsyncStream<[any Sendable]>) {
        self.base = base
    }

    public func makeAsyncIterator() -> AsyncIterator {
        AsyncIterator(base: base.makeAsyncIterator())
    }
}
