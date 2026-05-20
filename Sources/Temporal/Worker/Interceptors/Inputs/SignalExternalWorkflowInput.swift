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

/// Input structure containing parameters and context for external workflow signaling operations in interceptor chains.
public struct SignalExternalWorkflowInput<each Input: Sendable>: Sendable {
    /// Information about the current workflow execution.
    public var info: WorkflowInfo

    /// The workflow ID of the external workflow to signal.
    public var id: String

    /// The run ID of the external workflow.
    ///
    /// If `nil`, targets the latest run.
    public var runId: String?

    /// The name identifying the type of signal being sent to the external workflow.
    public var name: String

    /// Headers containing metadata and context information for external workflow signal execution.
    public var headers: [String: Api.Common.V1.Payload]

    /// The input parameters to be passed to the external workflow signal handler for processing.
    public var input: (repeat each Input)

    /// Creates a new signal external workflow input.
    ///
    /// - Parameters:
    ///   - info: Information about the current workflow execution.
    ///   - id: The workflow ID of the external workflow to signal.
    ///   - runId: The run ID of the external workflow. If `nil`, targets the latest run.
    ///   - name: The name identifying the type of signal being sent to the external workflow.
    ///   - headers: Headers containing metadata and context information for external workflow signal execution.
    ///   - input: The input parameters to be passed to the external workflow signal handler for processing.
    public init(
        info: WorkflowInfo,
        id: String,
        runId: String? = nil,
        name: String,
        headers: [String: Api.Common.V1.Payload],
        input: repeat each Input
    ) {
        self.info = info
        self.id = id
        self.runId = runId
        self.name = name
        self.headers = headers
        self.input = (repeat each input)
    }
}
