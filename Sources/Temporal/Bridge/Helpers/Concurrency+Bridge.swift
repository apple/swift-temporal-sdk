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

/// Helper type for holding a continuation in a reference counted object.
///
/// Convenient for manually retaining a reference and passing an Unmanaged pointer
/// into various C callbacks in the bridge layer.
final class ContinuationHolder<T> {
    let continuation: CheckedContinuation<T, any Error>

    init(_ continuation: CheckedContinuation<T, any Error>) {
        self.continuation = continuation
    }
}
