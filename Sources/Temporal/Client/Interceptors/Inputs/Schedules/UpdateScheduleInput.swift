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

/// Input parameters for updating workflow schedule configurations in client interceptors.
public struct UpdateScheduleInput<Input: Sendable>: Sendable {
    /// The unique identifier of the schedule to update.
    public var id: String

    /// Function that transforms the current schedule into an updated configuration.
    public var update: @Sendable (ScheduleDescription<Input>) async throws -> ScheduleUpdate<Input>?

    /// Optional gRPC call options for customizing the update request.
    public var callOptions: CallOptions?

    /// Creates a new update schedule input with the specified parameters.
    ///
    /// - Parameters:
    ///   - id: The unique identifier of the schedule to update.
    ///   - update: Function that transforms the current schedule into an updated configuration.
    ///   - callOptions: Optional gRPC call options for customizing the request.
    public init(
        id: String,
        update: @Sendable @escaping (ScheduleDescription<Input>) async throws -> ScheduleUpdate<Input>?,
        callOptions: CallOptions? = nil
    ) {
        self.id = id
        self.update = update
        self.callOptions = callOptions
    }

    /// Creates a new update schedule input with the specified parameters.
    ///
    /// - Parameters:
    ///   - id: The unique identifier of the schedule to update.
    ///   - workflowType: The workflow type associated with this schedule.
    ///   - update: Function that transforms the current schedule into an updated configuration.
    ///   - callOptions: Optional gRPC call options for customizing the request.
    public init<Workflow: WorkflowDefinition>(
        id: String,
        workflowType: Workflow.Type = Workflow.self,
        update: @Sendable @escaping (ScheduleDescription<Input>) async throws -> ScheduleUpdate<Input>?,
        callOptions: CallOptions? = nil
    ) where Workflow.Input == Input {
        self.id = id
        self.update = update
        self.callOptions = callOptions
    }
}
