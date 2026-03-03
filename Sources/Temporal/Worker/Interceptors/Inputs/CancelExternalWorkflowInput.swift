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

/// Input structure containing parameters for canceling an external workflow in interceptor chains.
public struct CancelExternalWorkflowInput: Sendable {
    /// The workflow id of the external workflow to cancel.
    public var id: String

    /// The run ID of the external workflow.
    ///
    /// If `nil`, targets the latest run.
    public var runId: String?
}
