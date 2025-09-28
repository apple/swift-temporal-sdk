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

/// Contains schedule configuration changes for update operations.
public struct ScheduleUpdate<Input: Sendable>: Sendable {
    /// The complete schedule configuration to apply as the update.
    public var schedule: Schedule<Input>

    /// Creates a schedule update with the specified configuration changes.
    ///
    /// - Parameter schedule: The complete schedule configuration to apply.
    public init(schedule: Schedule<Input>) {
        self.schedule = schedule
    }

    /// Creates a schedule update with the specified configuration changes.
    ///
    /// - Parameters:
    ///    - workflowType: The workflow type associated with this schedule update.
    ///    - schedule: The complete schedule configuration to apply.
    public init<Workflow: WorkflowDefinition>(
        workflowType: Workflow.Type = Workflow.self,
        schedule: Schedule<Workflow.Input>
    ) where Workflow.Input == Input {
        self.schedule = schedule
    }

    // TODO: SearchAttributeCollection
}
