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

/// Metadata about a Workflow Update.
public struct UpdateMeta: Hashable, Sendable {
    /// An ID with workflow-scoped uniqueness for this Update.
    public var updateID: String

    /// A string identifying the agent that requested this Update.
    public var identity: String?

    public init(updateID: String, identity: String? = nil) {
        self.updateID = updateID
        self.identity = identity
    }
}
