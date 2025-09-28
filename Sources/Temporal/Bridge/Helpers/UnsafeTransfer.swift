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

/// A wrapper type to make something `Sendable`.
///
/// This should only be used where currently sending isn't working or the type is not owned by us and we know what we are doing.
struct UnsafeTransfer<Wrapped>: @unchecked Sendable {
    /// The wrapped value.
    var wrapped: Wrapped
}
