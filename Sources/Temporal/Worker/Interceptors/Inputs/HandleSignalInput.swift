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

/// Input structure containing parameters and context for workflow signal handling in interceptor chains.
public struct HandleSignalInput<Signal: WorkflowSignalDefinition>: Sendable {
    /// The name identifying the type of signal being processed.
    public var name: String

    /// The signal definition containing type information and execution metadata.
    public var definition: Signal

    /// Headers containing metadata and context information for signal execution.
    public var headers: [String: TemporalPayload]

    /// The input parameters to be passed to the signal handler for execution.
    public var input: Signal.Input
}
