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

/// Input structure containing parameters and context for activity execution in interceptor chains.
public struct ExecuteActivityInput<Activity: ActivityDefinition>: Sendable {
    /// The activity definition containing type information and execution metadata.
    public var definition: Activity

    /// Headers containing metadata and context information for activity execution.
    public var headers: [String: Api.Common.V1.Payload]

    /// The input parameters to be passed to the activity for execution.
    public var input: Activity.Input

    /// Creates activity execution input with the specified definition, headers, and parameters.
    ///
    /// - Parameters:
    ///   - definition: The activity definition containing type and execution information.
    ///   - headers: The headers containing metadata and context for execution.
    ///   - input: The input parameters for activity execution.
    package init(definition: Activity, headers: [String: Api.Common.V1.Payload], input: Activity.Input) {
        self.definition = definition
        self.headers = headers
        self.input = input
    }
}
