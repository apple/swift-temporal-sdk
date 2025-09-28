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

/// The execution state of a pending activity in a workflow.
public enum PendingActivityState: Hashable, Sendable {
    /// Default state when no valid status is set.
    case unspecified
    /// Activity is scheduled but not yet started.
    case scheduled
    /// Activity is currently running.
    case started
    /// A cancellation has been requested for the activity.
    case cancelRequested
    /// Activity is paused on the server and not running on the worker.
    case paused
    /// Activity is running on the worker but paused on the server.
    case pauseRequested
}
