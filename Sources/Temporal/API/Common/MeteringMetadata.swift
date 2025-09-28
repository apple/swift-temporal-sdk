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

/// Metadata relevant for metering purposes.
public struct MeteringMetadata: Hashable, Sendable {
    /// Count of local activities which have begun an execution attempt during this workflow task, and whose first attempt occurred in some previous task.
    ///
    /// This is used for metering purposes, and does not affect workflow state.
    public var nonfirstLocalActivityExecutionAttempts: Int

    public init(nonfirstLocalActivityExecutionAttempts: Int) {
        self.nonfirstLocalActivityExecutionAttempts = nonfirstLocalActivityExecutionAttempts
    }
}
