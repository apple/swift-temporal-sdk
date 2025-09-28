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

/// Input structure containing parameters and context for workflow continue-as-new error generation in interceptor chains.
public struct MakeContinueAsNewErrorInput<each Input: Sendable>: Sendable {
    /// The configuration options for the continue-as-new workflow execution.
    public var options: ContinueAsNewOptions

    /// Headers containing metadata and context information for continue-as-new execution.
    public var headers: [String: TemporalPayload]

    /// The input parameters to be passed to the restarted workflow for execution.
    public var input: (repeat each Input)
}
