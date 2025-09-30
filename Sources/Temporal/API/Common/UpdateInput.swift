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

/// The input sent with a request as a part of a workflow update.
public struct UpdateInput: Hashable, Sendable {
    /// Headers that are passed with the Update from the requesting entity.
    ///
    /// These can include things like auth or tracing tokens.
    public var headers: [String: TemporalPayload]

    /// The name of the Update handler to invoke on the target Workflow.
    public var name: String

    /// The arguments to pass to the named Update handler.
    public var arguments: [TemporalPayload]

    public init(headers: [String: TemporalPayload], name: String, arguments: [TemporalPayload]) {
        self.headers = headers
        self.name = name
        self.arguments = arguments
    }
}
