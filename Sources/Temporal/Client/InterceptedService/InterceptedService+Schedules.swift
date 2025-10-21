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

package import struct GRPCCore.CallOptions

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

extension TemporalClient.InterceptedService {
    // MARK: Create

    /// Creates a new schedule for executing workflows on a recurring basis.
    ///
    /// This method creates a schedule that will automatically start workflow executions according
    /// to the specified timing configuration. The schedule persists in the Temporal cluster and
    /// continues to trigger workflows until it is deleted or paused.
    ///
    /// - Parameters:
    ///   - scheduleID: The unique identifier for the schedule. Defaults to a generated UUID.
    ///   - schedule: The schedule configuration defining timing and workflow specifications.
    ///   - options: Additional options for schedule behavior including policies and metadata.
    /// - Throws: An error if the schedule cannot be created due to validation failures or server issues.
    package func createSchedule<Input: Sendable>(
        id scheduleID: String = UUID().uuidString,
        schedule: Schedule<Input>,
        options: ScheduleOptions? = nil
    ) async throws {
        _ = try await self.interceptor.createSchedule(
            .init(
                id: scheduleID,
                schedule: schedule,
                options: options
            )
        )
    }

    // MARK: Describe

    /// Retrieves detailed information about the schedule's configuration and current state.
    ///
    /// This method fetches information about the schedule including its timing
    /// specifications, workflow configuration, execution history, and current operational state.
    /// The description provides a complete view of the schedule's setup and runtime status.
    ///
    /// - Parameters:
    ///    - id: The unique identifier of the schedule.
    ///    - inputType: The workflow input type associated with this schedule.
    ///    - callOptions: Optional gRPC call options for customizing the behavior of the underlying request.
    /// - Returns: A description of the schedule's configuration and state.
    /// - Throws: An error if the schedule cannot be accessed or does not exist.
    package func describeSchedule<Input: Sendable>(
        id: String,
        inputType: Input.Type = Input.self,
        callOptions: CallOptions? = nil
    ) async throws -> ScheduleDescription<Input> {
        try await self.interceptor.describeSchedule(
            .init(
                id: id,
                callOptions: callOptions
            )
        )
    }

    /// Executes backfill operations for the schedule across specified time periods.
    ///
    /// Backfill operations allow you to execute the schedule for past time periods as if those
    /// periods were happening right now. This is useful for handling missed executions, testing
    /// schedule behavior, or processing historical data with current workflow logic.
    ///
    /// - Parameters:
    ///    - id: The unique identifier of the schedule.
    ///    - backfills: An array of backfill periods defining the time ranges to process.
    ///    - callOptions: Optional gRPC call options for customizing the behavior of the underlying request.
    /// - Throws: An error if the backfill operation cannot be executed.
    package func backfillSchedule(
        id: String,
        backfills: [ScheduleBackfill],
        callOptions: CallOptions? = nil
    ) async throws {
        try await self.interceptor.backfillSchedule(
            .init(
                id: id,
                backfills: backfills,
                callOptions: callOptions
            )
        )
    }

    /// Manually triggers an immediate execution of the scheduled workflow.
    ///
    /// This method causes the schedule to start a workflow execution immediately, outside of its
    /// normal timing configuration. The triggered execution runs with the same workflow configuration
    /// and parameters as regular scheduled executions but ignores the timing specifications.
    ///
    /// - Parameters:
    ///    - id: The unique identifier of the schedule.
    ///    - overlap: Optional override for the schedule's overlap policy during this trigger.
    ///    - callOptions: Optional gRPC call options for customizing the behavior of the underlying request.
    /// - Throws: An error if the trigger operation cannot be executed.
    package func triggerSchedule(
        id: String,
        overlap: ScheduleOverlapPolicy? = nil,
        callOptions: CallOptions? = nil
    ) async throws {
        try await self.interceptor.triggerSchedule(
            .init(
                id: id,
                overlap: overlap,
                callOptions: callOptions
            )
        )
    }

    /// Updates the schedule's configuration with new timing or workflow specifications.
    ///
    /// This method allows modifying the schedule's configuration while it continues to operate.
    /// The update operation uses an optimistic concurrency control mechanism to handle concurrent
    /// modifications safely.
    ///
    /// - Parameters:
    ///   - id: The unique identifier of the schedule.
    ///   - inputType: The input type of the workflow triggered by the schedule.
    ///   - update: A closure that receives the current schedule state and returns proposed changes.
    ///   - callOptions: Optional gRPC call options for customizing the behavior of the underlying request.
    /// - Throws: An error if the update cannot be applied or validation fails.
    package func updateSchedule<Input: Sendable>(
        id: String,
        inputType: Input.Type = Input.self,
        _ update: @Sendable (ScheduleDescription<Input>) async throws -> ScheduleUpdate<Input>?,
        callOptions: CallOptions? = nil
    ) async throws {
        try await withoutActuallyEscaping(update) { update in
            try await self.interceptor.updateSchedule(
                .init(
                    id: id,
                    update: update,
                    callOptions: callOptions
                )
            )
        }
    }

    /// Pauses the schedule to temporarily stop workflow executions.
    ///
    /// Pausing a schedule stops it from triggering new workflow executions according to its
    /// timing configuration. The schedule retains all its configuration and can be resumed
    /// later using ``unpauseSchedule(id:note:callOptions:)``. Currently running workflows are not affected.
    ///
    /// - Parameters:
    ///    - id: The unique identifier of the schedule.
    ///    - note: An optional note documenting the reason for pausing the schedule.
    ///    - callOptions: Optional gRPC call options for customizing the behavior of the underlying request.
    /// - Throws: An error if the pause operation cannot be executed.
    package func pauseSchedule(
        id: String,
        note: String? = nil,
        callOptions: CallOptions? = nil
    ) async throws {
        try await self.interceptor.pauseSchedule(
            .init(
                id: id,
                note: note,
                callOptions: callOptions
            )
        )
    }

    /// Resumes a paused schedule to allow workflow executions to continue.
    ///
    /// Unpausing a schedule restores its normal operation, allowing it to trigger workflow
    /// executions according to its timing configuration. The schedule resumes from its current
    /// state without attempting to catch up on missed executions during the pause period.
    ///
    /// - Parameters:
    ///    - id: The unique identifier of the schedule.
    ///    - note: An optional note documenting the reason for unpausing the schedule.
    ///    - callOptions: Optional gRPC call options for customizing the behavior of the underlying request.
    /// - Throws: An error if the unpause operation cannot be executed.
    package func unpauseSchedule(
        id: String,
        note: String? = nil,
        callOptions: CallOptions? = nil
    ) async throws {
        try await self.interceptor.unpauseSchedule(
            .init(
                id: id,
                note: note,
                callOptions: callOptions
            )
        )
    }

    /// Permanently deletes the schedule from the Temporal cluster.
    ///
    /// This method removes the schedule completely, stopping all future workflow executions
    /// and removing the schedule's configuration and history from the cluster. This operation
    /// is irreversible and should be used with caution.
    ///
    /// - Parameters:
    ///    - id: The unique identifier of the schedule.
    ///    - callOptions: Optional gRPC call options for customizing the behavior of the underlying request.
    /// - Throws: An error if the deletion operation cannot be executed.
    package func deleteSchedule(
        id: String,
        callOptions: CallOptions? = nil
    ) async throws {
        try await self.interceptor.deleteSchedule(
            .init(
                id: id,
                callOptions: callOptions
            )
        )
    }
}
