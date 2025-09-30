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

/// Structure containing information about an activity scheduled for execution.
public struct ActivityExecutionInfo: Sendable, Hashable {
    /// The unique name identifying the activity to be executed.
    public var name: String

    /// Creates activity execution information with the specified activity name.
    ///
    /// - Parameter name: The unique name identifying the activity to execute.
    public init(name: String) {
        self.name = name
    }
}
