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

/// Input structure containing parameters and context for child workflow signaling operations in interceptor chains.
public struct SignalChildWorkflowInput<each Input: Sendable>: Sendable {
    /// The unique identifier of the child workflow to signal.
    public var id: String

    /// The name identifying the type of signal being sent to the child workflow.
    public var name: String

    /// Headers containing metadata and context information for child workflow signal execution.
    public var headers: [String: TemporalPayload]

    /// The input parameters to be passed to the child workflow signal handler for processing.
    public var input: (repeat each Input)
}
