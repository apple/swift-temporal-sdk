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

/// Input structure containing parameters and context for activity scheduling operations in interceptor chains.
public struct ScheduleLocalActivityInput<each Input: Sendable>: Sendable {
    /// The name identifying the type of activity to be scheduled for execution.
    public var name: String

    /// The configuration options controlling how the activity should be executed.
    public var options: LocalActivityOptions

    /// Headers containing metadata and context information for activity execution.
    public var headers: [String: TemporalPayload]

    /// The input parameters to be passed to the activity for execution.
    public var input: (repeat each Input)

    /// Creates a new activity scheduling input with the specified parameters.
    ///
    /// - Parameters:
    ///   - name: The activity name identifying the activity type to execute.
    ///   - options: The configuration options controlling activity execution behavior.
    ///   - headers: The metadata and context headers for activity execution.
    ///   - input: The input parameters to pass to the activity, of varying types and counts.
    package init(
        name: String,
        options: LocalActivityOptions,
        headers: [String: TemporalPayload],
        input: (repeat each Input)
    ) {
        self.name = name
        self.options = options
        self.headers = headers
        self.input = input
    }
}
