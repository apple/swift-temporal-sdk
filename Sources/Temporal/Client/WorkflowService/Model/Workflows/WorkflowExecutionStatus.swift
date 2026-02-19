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

/// The current execution status of a workflow in the Temporal system.
// TODO: Revisit if this should be an enum
public enum WorkflowExecutionStatus: Hashable, Sendable {
    /// The workflow is currently executing and processing tasks.
    case running

    /// The workflow has completed successfully and returned a result.
    case completed

    /// The workflow has failed due to an unhandled error or exception.
    case failed

    /// The workflow was explicitly cancelled before completion.
    case canceled

    /// The workflow was forcibly terminated by an external action.
    case terminated

    /// The workflow restarted as a new execution to continue processing.
    case continuedAsNew

    /// The workflow exceeded its execution timeout and was terminated.
    case timedOut

    /// The workflow has been paused and is not currently executing.
    case paused
}
