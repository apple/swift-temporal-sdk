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
    ///   - id: The unique identifier for the schedule. Defaults to a generated UUID.
    ///   - workflowType: The workflow type associated with this schedule.
    ///   - schedule: The schedule configuration defining timing and workflow specifications.
    ///   - options: Additional options for schedule behavior including policies and metadata.
    /// - Returns: A handle for managing the created schedule.
    /// - Throws: An error if the schedule cannot be created due to validation failures or server issues.
    public func createSchedule<Workflow: WorkflowDefinition>(
        id: String = UUID().uuidString,
        workflowType: Workflow.Type = Workflow.self,
        schedule: Schedule<Workflow.Input>,
        options: ScheduleOptions? = nil
    ) async throws -> ScheduleHandle<Workflow> {
        let untypedHandle = try await self.createSchedule(id: id, schedule: schedule, options: options)

        return ScheduleHandle(
            untypedHandle: untypedHandle
        )
    }

    /// Creates a handle for managing an existing schedule.
    ///
    /// This method creates a ``ScheduleHandle`` that can be used to interact with an existing
    /// schedule without needing to create a new one. The handle provides access to schedule
    /// operations such as pausing, unpausing, updating, triggering, and deleting.
    ///
    /// - Parameter id: The unique identifier of the existing schedule.
    /// - Returns: A handle for managing the schedule with the specified ID.
    public func scheduleHandle<Workflow: WorkflowDefinition>(
        id: String
    ) -> ScheduleHandle<Workflow> {
        let untypedHandle = self.untypedScheduleHandle(id: id)

        return ScheduleHandle(
            untypedHandle: untypedHandle
        )
    }
}
