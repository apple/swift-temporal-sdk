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

/// Input parameters for creating workflow schedules in client interceptors.
public struct CreateScheduleInput<Input: Sendable>: Sendable {
    /// The unique identifier for the schedule.
    public var id: String

    /// The complete schedule configuration including specification, action, and policies.
    public var schedule: Schedule<Input>

    /// Optional configuration options for the schedule creation operation.
    public var options: ScheduleOptions?

    /// Optional gRPC call options for customizing the schedule creation request.
    public var callOptions: CallOptions?

    /// Creates a new create schedule input with the specified parameters.
    ///
    /// - Parameters:
    ///   - id: The unique identifier for the schedule.
    ///   - schedule: The complete schedule configuration including specification, action, and policies.
    ///   - options: Optional configuration options for the schedule creation operation.
    ///   - callOptions: Optional gRPC call options for customizing the request.
    public init(
        id: String,
        schedule: Schedule<Input>,
        options: ScheduleOptions? = nil,
        callOptions: CallOptions? = nil
    ) {
        self.id = id
        self.schedule = schedule
        self.options = options
        self.callOptions = callOptions
    }

    /// Creates a new create schedule input with the specified parameters.
    ///
    /// - Parameters:
    ///   - id: The unique identifier for the schedule.
    ///   - workflowType: The workflow type associated with this schedule.
    ///   - schedule: The complete schedule configuration including specification, action, and policies.
    ///   - options: Optional configuration options for the schedule creation operation.
    ///   - callOptions: Optional gRPC call options for customizing the request.
    public init<Workflow: WorkflowDefinition>(
        id: String,
        workflowType: Workflow.Type = Workflow.self,
        schedule: Schedule<Workflow.Input>,
        options: ScheduleOptions? = nil,
        callOptions: CallOptions? = nil
    ) where Workflow.Input == Input {
        self.id = id
        self.schedule = schedule
        self.options = options
        self.callOptions = callOptions
    }
}
