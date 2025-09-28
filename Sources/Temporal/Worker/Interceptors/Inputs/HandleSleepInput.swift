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

/// Input structure containing parameters and context for workflow sleep operations in interceptor chains.
public struct HandleSleepInput: Sendable {
    /// The duration of the sleep operation.
    public var duration: Duration

    /// Optional identifier for the sleep operation, potentially visible in monitoring interfaces.
    ///
    /// While it can be normal text, it is best to treat as a timer ID.
    ///
    /// - Important: This is currently experimental.
    public var summary: String?
}
