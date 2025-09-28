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

/// Input structure containing parameters and context for workflow update handling in interceptor chains.
public struct HandleUpdateInput<Update: WorkflowUpdateDefinition>: Sendable {
    /// The unique identifier for this specific update request.
    public var id: String

    /// The name identifying the type of update being executed.
    public var name: String

    /// The update definition containing type information and execution metadata.
    public var definition: Update

    /// Headers containing metadata and context information for update execution.
    public var headers: [String: TemporalPayload]

    /// The input parameters to be passed to the update handler for execution.
    public var input: Update.Input
}
