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

/// Input structure containing parameters and context for workflow signal handling in interceptor chains.
public struct HandleSignalInput<Signal: WorkflowSignalDefinition>: Sendable {
    /// Information about the current workflow execution.
    public var info: WorkflowInfo

    /// The name identifying the type of signal being processed.
    public var name: String

    /// The signal definition containing type information and execution metadata.
    public var definition: Signal

    /// Headers containing metadata and context information for signal execution.
    public var headers: [String: Api.Common.V1.Payload]

    /// The input parameters to be passed to the signal handler for execution.
    public var input: Signal.Input

    /// Creates a new handle signal input.
    ///
    /// - Parameters:
    ///   - info: Information about the current workflow execution.
    ///   - name: The name identifying the type of signal being processed.
    ///   - definition: The signal definition containing type information and execution metadata.
    ///   - headers: Headers containing metadata and context information for signal execution.
    ///   - input: The input parameters to be passed to the signal handler for execution.
    public init(
        info: WorkflowInfo,
        name: String,
        definition: Signal,
        headers: [String: Api.Common.V1.Payload],
        input: Signal.Input
    ) {
        self.info = info
        self.name = name
        self.definition = definition
        self.headers = headers
        self.input = input
    }
}
