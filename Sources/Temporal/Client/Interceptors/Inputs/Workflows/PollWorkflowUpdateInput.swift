//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Temporal SDK open source project
//
// Copyright (c) 2026 Apple Inc. and the Swift Temporal SDK project authors
// Licensed under MIT License
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Swift Temporal SDK project authors
//
// SPDX-License-Identifier: MIT
//
//===----------------------------------------------------------------------===//

public import struct GRPCCore.CallOptions

/// Input parameters for polling a workflow update result in client interceptors.
public struct PollWorkflowUpdateInput: Sendable {
    /// The unique identifier of the workflow whose update to poll.
    public var workflowID: String

    /// The specific run ID of the workflow execution whose update to poll.
    public var runID: String?

    /// The unique identifier of the update to poll for results.
    public var updateID: String

    /// Optional gRPC call options for customizing the poll request.
    public var callOptions: CallOptions?

    /// Creates a new poll workflow update input with the specified parameters.
    ///
    /// - Parameters:
    ///   - workflowID: The unique identifier of the workflow whose update to poll.
    ///   - runID: The specific run ID of the workflow execution whose update to poll.
    ///   - updateID: The unique identifier of the update to poll for results.
    ///   - callOptions: Optional gRPC call options for customizing the request.
    public init(
        workflowID: String,
        runID: String? = nil,
        updateID: String,
        callOptions: CallOptions? = nil
    ) {
        self.workflowID = workflowID
        self.runID = runID
        self.updateID = updateID
        self.callOptions = callOptions
    }
}
