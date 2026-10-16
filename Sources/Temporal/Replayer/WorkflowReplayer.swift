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

/// Replays workflow histories to verify workflow code compatibility.
///
/// ``WorkflowReplayer`` is used for testing workflow code changes against recorded
/// execution histories. It helps detect non-deterministic changes before they cause
/// production failures by running workflow code against historical events without
/// connecting to a Temporal server.
///
/// ## Usage
///
/// Create a replayer with the workflow types you want to test:
///
/// ```swift
/// var config = WorkflowReplayer.Configuration()
/// config.workflows.append(MyWorkflow.self)
/// config.workflows.append(AnotherWorkflow.self)
///
/// let replayer = WorkflowReplayer(configuration: config)
///
/// let history = try WorkflowHistory.fromJSON(
///     workflowID: "my-workflow-123",
///     json: jsonString
/// )
///
/// let result = try await replayer.replayWorkflow(history: history)
/// print("Replay succeeded: \(result.succeeded)")
/// ```
public final class WorkflowReplayer: Sendable {
    /// The configuration for this replayer.
    private let configuration: Configuration

    /// Creates a new workflow replayer with the given configuration.
    ///
    /// At least one workflow must be registered, either in ``Configuration/workflows`` or by a plugin
    /// set on ``Configuration/plugins``.
    ///
    /// - Parameter configuration: The configuration specifying which workflows to replay
    ///   and how to process them.
    ///
    /// - Warning: Registrations are not deduplicated, so a workflow name in
    ///   ``Configuration/workflows`` that a plugin also registers makes
    ///   ``replayWorkflow(history:throwOnReplayFailure:)`` throw.
    public init(configuration: Configuration) {
        var configuration = configuration
        configuration.applyPlugins()
        precondition(
            !configuration.workflows.isEmpty,
            "At least one workflow must be registered with the replayer"
        )
        self.configuration = configuration
    }

    /// Replays a single workflow history.
    ///
    /// Each plugin's ``WorkerPlugin/runReplayer(configuration:next:)`` wraps the replay; the first
    /// plugin is the outermost wrap.
    ///
    /// - Parameters:
    ///   - history: The workflow history to replay.
    ///   - throwOnReplayFailure: If `true` (the default), throws an error when replay
    ///     fails due to non-determinism or other issues. If `false`, returns a result
    ///     with the failure information.
    /// - Returns: A ``WorkflowReplayResult`` containing the replay outcome.
    /// - Throws: ``WorkflowNondeterminismError`` if the workflow code is incompatible
    ///   with the history and `throwOnReplayFailure` is `true`. Other errors may be
    ///   thrown for infrastructure failures.
    public func replayWorkflow(
        history: WorkflowHistory,
        throwOnReplayFailure: Bool = true
    ) async throws -> WorkflowReplayResult {
        try await applyReplayerRunChain(
            plugins: self.configuration.plugins[...],
            configuration: self.configuration
        ) {
            let runner = try WorkflowHistoryRunner(configuration: self.configuration)
            return try await runner.replayWorkflow(
                history: history,
                throwOnReplayFailure: throwOnReplayFailure
            )
        }
    }

    /// Replays multiple workflow histories.
    ///
    /// Each history goes through ``replayWorkflow(history:throwOnReplayFailure:)``, so plugins wrap
    /// each replay rather than the batch.
    ///
    /// - Parameters:
    ///   - histories: The workflow histories to replay.
    ///   - throwOnReplayFailure: If `true` (the default), throws on the first replay
    ///     failure. If `false`, continues replaying all histories and returns results
    ///     for each. A plugin's error stops the batch either way.
    /// - Returns: An array of ``WorkflowReplayResult`` containing the outcome for each
    ///   history, in the same order as the input.
    /// - Throws: ``WorkflowNondeterminismError`` if any workflow code is incompatible
    ///   with its history and `throwOnReplayFailure` is `true`.
    public func replayWorkflows(
        histories: [WorkflowHistory],
        throwOnReplayFailure: Bool = true
    ) async throws -> [WorkflowReplayResult] {
        var results: [WorkflowReplayResult] = []
        results.reserveCapacity(histories.count)

        for history in histories {
            let result = try await self.replayWorkflow(
                history: history,
                throwOnReplayFailure: throwOnReplayFailure
            )
            results.append(result)
        }

        return results
    }
}
