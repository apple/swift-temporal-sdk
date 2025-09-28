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

/// An `AsyncSequence` that takes an underlying sequence of collections (for example paginated batches)
/// and emits each element in order as a continuous, flattened stream, preserving Swift’s structured concurrency.
package struct FlattenedAsyncSequence<Element, Base: AsyncSequence>: AsyncSequence where Base.Element: Collection<Element> {
    package typealias Element = Base.Element.Element
    package typealias Failure = Base.Failure

    package struct Iterator: AsyncIteratorProtocol {
        struct CurrentCollection {
            var collection: Base.Element
            var currentIndex: Base.Element.Index
        }
        var base: Base.AsyncIterator?
        var currentCollection: CurrentCollection?

        package mutating func next(isolation actor: isolated (any Actor)? = #isolation) async throws(Failure) -> Element? {
            func nextElement(currentCollection: CurrentCollection) -> Element? {
                if currentCollection.currentIndex >= currentCollection.collection.endIndex {
                    self.currentCollection = nil
                    return nil
                }

                let element = currentCollection.collection[currentCollection.currentIndex]
                let nextIndex = currentCollection.collection.index(after: currentCollection.currentIndex)

                if nextIndex == currentCollection.collection.endIndex {
                    self.currentCollection = nil
                } else {
                    self.currentCollection?.currentIndex = nextIndex
                }

                return element
            }

            guard var base else {
                return nil
            }
            defer {
                self.base = base
            }

            while true {
                // swift-format-ignore: UseEarlyExits
                if let currentCollection {
                    guard let element = nextElement(currentCollection: currentCollection) else {
                        continue
                    }
                    return element
                } else {
                    guard let nextCollection = try await base.next(isolation: actor) else {
                        self.base = nil
                        return nil
                    }

                    let currentCollection = CurrentCollection(collection: nextCollection, currentIndex: nextCollection.startIndex)
                    self.currentCollection = currentCollection

                    guard let element = nextElement(currentCollection: currentCollection) else {
                        continue
                    }
                    return element
                }
            }
        }
    }

    let base: Base

    package func makeAsyncIterator() -> Iterator {
        Iterator(base: base.makeAsyncIterator())
    }
}

extension FlattenedAsyncSequence: Sendable where Base: Sendable {}

extension AsyncSequence where Element: Collection {
    /// Returns an asynchronous sequence that iterates over all elements of each `Collection` in the base sequence,
    /// combining the individual sequences into one flattened `AsyncSequence`.
    package func flattened() -> FlattenedAsyncSequence<Element.Element, Self> {
        FlattenedAsyncSequence(base: self)
    }
}
