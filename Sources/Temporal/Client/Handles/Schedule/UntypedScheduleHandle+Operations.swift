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

import struct GRPCCore.CallOptions

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

extension UntypedScheduleHandle {
    // MARK: Describe

    /// Retrieves detailed information about the schedule's configuration and current state.
    ///
    /// This method fetches information about the schedule including its timing
    /// specifications, workflow configuration, execution history, and current operational state.
    /// The description provides a complete view of the schedule's setup and runtime status.
    ///
    /// - Parameters:
    ///    - inputType: The input type of the workflow associated with this schedule.
    ///    - callOptions: Optional gRPC call options for customizing the behavior of the underlying request.
    /// - Returns: A description of the schedule's configuration and state.
    /// - Throws: An error if the schedule cannot be accessed or does not exist.
    public func describe<Input: Sendable>(
        inputType: Input.Type = Input.self,
        callOptions: CallOptions? = nil
    ) async throws -> ScheduleDescription<Input> {
        try await self.interceptor.describeSchedule(
            .init(
                id: self.id,
                callOptions: callOptions
            )
        )
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
        try await self.interceptor.backfillSchedule(
            .init(
                id: self.id,
                backfills: backfills,
                callOptions: callOptions
            )
        )
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
        try await self.interceptor.triggerSchedule(
            .init(
                id: self.id,
                overlap: overlap,
                callOptions: callOptions
            )
        )
    }

    // MARK: Update

    /// Updates the schedule's configuration with new timing or workflow specifications.
    ///
    /// This method allows modifying the schedule's configuration while it continues to operate.
    /// The update operation uses an optimistic concurrency control mechanism to handle concurrent
    /// modifications safely.
    ///
    /// - Parameters:
    ///   - inputType:The input type of the workflow associated with this schedule update.
    ///   - update: A closure that receives the current schedule state and returns proposed changes.
    ///   - callOptions: Optional gRPC call options for customizing the behavior of the underlying request.
    /// - Throws: An error if the update cannot be applied or validation fails.
    public func update<Input: Sendable>(
        inputType: Input.Type = Input.self,
        _ update: @Sendable (ScheduleDescription<Input>) async throws -> ScheduleUpdate<Input>?,
        callOptions: CallOptions? = nil
    ) async throws {
        try await withoutActuallyEscaping(update) { update in
            try await self.interceptor.updateSchedule(
                .init(
                    id: self.id,
                    update: update,
                    callOptions: callOptions
                )
            )
        }
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
        try await self.interceptor.pauseSchedule(
            .init(
                id: self.id,
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
    ///    - note: An optional note documenting the reason for unpausing the schedule.
    ///    - callOptions: Optional gRPC call options for customizing the behavior of the underlying request.
    /// - Throws: An error if the unpause operation cannot be executed.
    public func unpause(note: String? = nil, callOptions: CallOptions? = nil) async throws {
        try await self.interceptor.unpauseSchedule(
            .init(
                id: self.id,
                note: note,
                callOptions: callOptions
            )
        )
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
        try await self.interceptor.deleteSchedule(
            .init(
                id: self.id,
                callOptions: callOptions
            )
        )
    }
}

extension TemporalClient.Interceptor {
    func describeSchedule<Input>(
        _ input: DescribeScheduleInput
    ) async throws -> ScheduleDescription<Input> {
        try await self.intercept(ClientOutboundInterceptor.describeSchedule, input: input) { input in
            try await self.workflowService.describeSchedule(
                id: input.id,
                callOptions: input.callOptions
            )
        }
    }

    func backfillSchedule(
        _ input: BackfillScheduleInput
    ) async throws {
        try await self.intercept(ClientOutboundInterceptor.backfillSchedule, input: input) { input in
            try await self.workflowService.backfillSchedule(
                id: input.id,
                backfills: input.backfills,
                callOptions: input.callOptions
            )
        }
    }

    func deleteSchedule(
        _ input: DeleteScheduleInput
    ) async throws {
        try await self.intercept(ClientOutboundInterceptor.deleteSchedule, input: input) { input in
            try await self.workflowService.deleteSchedule(
                id: input.id,
                callOptions: input.callOptions
            )
        }
    }

    func pauseSchedule(
        _ input: PauseScheduleInput
    ) async throws {
        try await self.intercept(ClientOutboundInterceptor.pauseSchedule, input: input) { input in
            try await self.workflowService.pauseSchedule(
                id: input.id,
                note: input.note,
                callOptions: input.callOptions
            )
        }
    }

    func triggerSchedule(
        _ input: TriggerScheduleInput
    ) async throws {
        try await self.intercept(ClientOutboundInterceptor.triggerSchedule, input: input) { input in
            try await self.workflowService.triggerSchedule(
                id: input.id,
                overlap: input.overlap,
                callOptions: input.callOptions
            )
        }
    }

    func unpauseSchedule(
        _ input: UnpauseScheduleInput
    ) async throws {
        try await self.intercept(ClientOutboundInterceptor.unpauseSchedule, input: input) { input in
            try await self.workflowService.unpauseSchedule(
                id: input.id,
                note: input.note,
                callOptions: input.callOptions
            )
        }
    }

    func updateSchedule<Input>(
        _ input: UpdateScheduleInput<Input>
    ) async throws {
        try await self.intercept(ClientOutboundInterceptor.updateSchedule, input: input) { input in
            try await self.workflowService.updateSchedule(
                id: input.id,
                input.update,
                callOptions: input.callOptions
            )
        }
    }
}
