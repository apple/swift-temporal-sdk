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

/// The client request that triggers a Workflow Update.
public struct UpdateRequest: Hashable, Sendable {
    public var meta: UpdateMeta?

    public var input: UpdateInput?

    public init(meta: UpdateMeta? = nil, input: UpdateInput? = nil) {
        self.meta = meta
        self.input = input
    }
}
