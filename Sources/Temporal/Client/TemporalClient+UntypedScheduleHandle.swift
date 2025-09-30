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

extension TemporalClient {
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
    /// - Returns: A handle for managing the created schedule.
    /// - Throws: An error if the schedule cannot be created due to validation failures or server issues.
    public func createSchedule<Input: Sendable>(
        id scheduleID: String = UUID().uuidString,
        schedule: Schedule<Input>,
        options: ScheduleOptions? = nil
    ) async throws -> UntypedScheduleHandle {
        try await self.interceptor.createSchedule(
            .init(
                id: scheduleID,
                schedule: schedule,
                options: options
            )
        )
    }

    /// Lists schedules in the namespace with optional filtering.
    ///
    /// This method returns an async sequence of schedule descriptions that match the specified
    /// query criteria. The method handles pagination automatically, providing a flattened view
    /// of all matching schedules across multiple pages of results.
    ///
    /// - Parameters:
    ///    - query: The visibility list filter query for matching schedules. Defaults to empty (returns all schedules).
    ///    - callOptions: Optional gRPC call options for customizing the behavior of the underlying request.
    /// - Returns: An async sequence of schedule descriptions matching the query criteria.
    /// - Throws: An error if the listing operation fails or query syntax is invalid.
    public func listSchedules(
        query: String = "",
        callOptions: CallOptions? = nil
    ) async throws -> some AsyncSequence<ScheduleListDescription, any Error> & Sendable {
        try await self.interceptor.listSchedules(
            .init(
                query: query,
                callOptions: callOptions
            )
        )
    }

    /// Creates a handle for managing an existing schedule, without encapsulating the ``WorkflowDefinition`` type.
    ///
    /// This method creates an ``UntypedScheduleHandle`` that can be used to interact with an existing
    /// schedule without needing to create a new one. The handle provides access to schedule
    /// operations such as pausing, unpausing, updating, triggering, and deleting.
    ///
    /// - Parameter id: The unique identifier of the existing schedule.
    /// - Returns: An untyped handle for managing the schedule with the specified ID.
    public func untypedScheduleHandle(
        id: String
    ) -> UntypedScheduleHandle {
        UntypedScheduleHandle(
            interceptor: self.interceptor,
            id: id
        )
    }
}

extension TemporalClient.Interceptor {
    func createSchedule<Input>(
        _ input: CreateScheduleInput<Input>
    ) async throws -> UntypedScheduleHandle {
        try await self.intercept(ClientOutboundInterceptor.createSchedule, input: input) { input in
            try await self.workflowService.createSchedule(
                id: input.id,
                schedule: input.schedule,
                options: input.options
            )

            return UntypedScheduleHandle(
                interceptor: self,
                id: input.id
            )
        }
    }

    func listSchedules(
        _ input: ListSchedulesInput
    ) async throws -> some AsyncSequence<ScheduleListDescription, any Error> & Sendable {
        try await self.intercept(ClientOutboundInterceptor.listSchedules, input: input) { input in
            try await self.workflowService.listSchedules(
                query: input.query ?? "",
                callOptions: input.callOptions
            )
        }
    }
}
