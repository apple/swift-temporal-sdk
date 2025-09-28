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

import struct GRPCCore.CallOptions

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

extension ScheduleHandle {
    // MARK: Describe

    /// Retrieves detailed information about the schedule's configuration and current state.
    ///
    /// This method fetches information about the schedule including its timing
    /// specifications, workflow configuration, execution history, and current operational state.
    /// The description provides a complete view of the schedule's setup and runtime status.
    ///
    /// - Parameters:
    ///    - callOptions: Optional gRPC call options for customizing the behavior of the underlying request.
    /// - Returns: A description of the schedule's configuration and state.
    /// - Throws: An error if the schedule cannot be accessed or does not exist.
    public func describe(
        callOptions: CallOptions? = nil
    ) async throws -> ScheduleDescription<Workflow.Input> {
        try await self.untypedHandle.describe(callOptions: callOptions)
    }

    // MARK: Backfill

    /// Executes backfill operations for the schedule across specified time periods.
    ///
    /// Backfill operations allow you to execute the schedule for past time periods as if those
    /// periods were happening right now. This is useful for handling missed executions, testing
    /// schedule behavior, or processing historical data with current workflow logic.
    ///
    /// - Parameters:
    ///    - backfills: An array of backfill periods defining the time ranges to process.
    ///    - callOptions: Optional gRPC call options for customizing the behavior of the underlying request.
    /// - Throws: An error if the backfill operation cannot be executed.
    public func backfill(
        backfills: [ScheduleBackfill],
        callOptions: CallOptions? = nil
    ) async throws {
        try await self.untypedHandle.backfill(backfills: backfills, callOptions: callOptions)
    }

    // MARK: Trigger

    /// Manually triggers an immediate execution of the scheduled workflow.
    ///
    /// This method causes the schedule to start a workflow execution immediately, outside of its
    /// normal timing configuration. The triggered execution runs with the same workflow configuration
    /// and parameters as regular scheduled executions but ignores the timing specifications.
    ///
    /// - Parameters:
    ///    - overlap: Optional override for the schedule's overlap policy during this trigger.
    ///    - callOptions: Optional gRPC call options for customizing the behavior of the underlying request.
    /// - Throws: An error if the trigger operation cannot be executed.
    public func trigger(overlap: ScheduleOverlapPolicy? = nil, callOptions: CallOptions? = nil) async throws {
        try await self.untypedHandle.trigger(overlap: overlap, callOptions: callOptions)
    }

    // MARK: Update

    /// Updates the schedule's configuration with new timing or workflow specifications.
    ///
    /// This method allows modifying the schedule's configuration while it continues to operate.
    /// The update operation uses an optimistic concurrency control mechanism to handle concurrent
    /// modifications safely.
    ///
    /// - Parameters:
    ///   - update: A closure that receives the current schedule state and returns proposed changes.
    ///   - callOptions: Optional gRPC call options for customizing the behavior of the underlying request.
    /// - Throws: An error if the update cannot be applied or validation fails.
    public func update(
        _ update: @Sendable (ScheduleDescription<Workflow.Input>) async throws -> ScheduleUpdate<Workflow.Input>?,
        callOptions: CallOptions? = nil
    ) async throws {
        try await self.untypedHandle.update(update, callOptions: callOptions)
    }

    // MARK: Pause

    /// Pauses the schedule to temporarily stop workflow executions.
    ///
    /// Pausing a schedule stops it from triggering new workflow executions according to its
    /// timing configuration. The schedule retains all its configuration and can be resumed
    /// later using ``unpause(note:callOptions:)``. Currently running workflows are not affected.
    ///
    /// - Parameters:
    ///    - note: An optional note documenting the reason for pausing the schedule.
    ///    - callOptions: Optional gRPC call options for customizing the behavior of the underlying request.
    /// - Throws: An error if the pause operation cannot be executed.
    public func pause(note: String? = nil, callOptions: CallOptions? = nil) async throws {
        try await self.untypedHandle.pause(note: note, callOptions: callOptions)
    }

    /// Resumes a paused schedule to allow workflow executions to continue.
    ///
    /// Unpausing a schedule restores its normal operation, allowing it to trigger workflow
    /// executions according to its timing configuration. The schedule resumes from its current
    /// state without attempting to catch up on missed executions during the pause period.
    ///
    /// - Parameters:
    ///    - note: An optional note documenting the reason for unpausing the schedule.
    ///    - callOptions: Optional gRPC call options for customizing the behavior of the underlying request.
    /// - Throws: An error if the unpause operation cannot be executed.
    public func unpause(note: String? = nil, callOptions: CallOptions? = nil) async throws {
        try await self.untypedHandle.unpause(note: note, callOptions: callOptions)
    }

    // MARK: Delete

    /// Permanently deletes the schedule from the Temporal cluster.
    ///
    /// This method removes the schedule completely, stopping all future workflow executions
    /// and removing the schedule's configuration and history from the cluster. This operation
    /// is irreversible and should be used with caution.
    ///
    /// - Parameter callOptions: Optional gRPC call options for customizing the behavior of the underlying request.
    /// - Throws: An error if the deletion operation cannot be executed.
    public func delete(callOptions: CallOptions? = nil) async throws {
        try await self.untypedHandle.delete(callOptions: callOptions)
    }
}
