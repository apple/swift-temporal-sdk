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

/// The result of replaying a workflow from history.
public struct WorkflowReplayResult: Sendable {
    /// The history that was replayed.
    public var history: WorkflowHistory

    /// The replay failure, if any occurred.
    ///
    /// This property is `nil` for successful replays. When a replay fails, this
    /// will contain one of the following error types:
    ///
    /// - ``WorkflowNondeterminismError``: The workflow code has changed in a way
    ///   that is incompatible with the recorded history
    /// - ``InvalidOperationError``: An unexpected error occurred during replay
    ///
    /// Note: Normal workflow failures (e.g., ``ApplicationError`` thrown by the
    /// workflow) are not captured here as they represent valid workflow behavior
    /// that was correctly replayed.
    public var replayFailure: (any Error)?

    /// Creates a new replay result.
    ///
    /// - Parameters:
    ///   - history: The history that was replayed.
    ///   - replayFailure: The replay failure, if any occurred.
    public init(history: WorkflowHistory, replayFailure: (any Error)? = nil) {
        self.history = history
        self.replayFailure = replayFailure
    }
}
