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

/// The stage to wait for when starting a workflow update.
///
/// When starting a workflow update, this value determines how long the server should wait
/// before returning a response. If the specified stage is not reached before the server timeout,
/// the server returns the actual stage reached.
public enum WorkflowUpdateStage: Sendable {
    /// Wait until the update is admitted by the server.
    ///
    /// The update request has been received by the server but may not yet have been
    /// delivered to a worker. This does not wait for any acknowledgement from a worker.
    case admitted

    /// Wait until the update is accepted by the workflow.
    ///
    /// The update has passed validation on a worker and has been accepted for processing.
    case accepted

    /// Wait until the update is completed by the workflow.
    ///
    /// The update has executed to completion on a worker and has either been rejected
    /// or returned a value or an error.
    case completed
}
