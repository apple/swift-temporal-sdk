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

/// A definition for periodically executing workflows on a recurring schedule.
public struct Schedule<Input: Sendable>: Sendable {
    /// The action to execute when the schedule triggers.
    public var action: ScheduleAction<Input>

    /// The timing specification that defines when the action should be executed.
    public var specification: ScheduleSpecification

    /// The execution policy controlling schedule behavior and overlap handling.
    public var policy: SchedulePolicy

    /// The current operational state of the schedule.
    public var state: ScheduleState

    /// Creates a schedule definition for recurring workflow execution.
    ///
    /// - Parameters:
    ///   - action: The action to execute when the schedule triggers (typically workflow execution).
    ///   - specification: The timing specification defining when actions should occur.
    ///   - policy: The execution policy for overlap and failure handling. Defaults to standard behavior.
    ///   - state: The initial operational state of the schedule. Defaults to active state.
    public init(
        action: ScheduleAction<Input>,
        specification: ScheduleSpecification,
        policy: SchedulePolicy = .init(),
        state: ScheduleState = .init()
    ) {
        self.action = action
        self.specification = specification
        self.policy = policy
        self.state = state
    }

    /// Creates a schedule definition for recurring workflow execution.
    ///
    /// - Parameters:
    ///   - workflowType: The workflow type associated with this schedule.
    ///   - action: The action to execute when the schedule triggers (typically workflow execution).
    ///   - specification: The timing specification defining when actions should occur.
    ///   - policy: The execution policy for overlap and failure handling. Defaults to standard behavior.
    ///   - state: The initial operational state of the schedule. Defaults to active state.
    public init<Workflow: WorkflowDefinition>(
        workflowType: Workflow.Type = Workflow.self,
        action: ScheduleAction<Workflow.Input>,
        specification: ScheduleSpecification,
        policy: SchedulePolicy = .init(),
        state: ScheduleState = .init()
    ) where Workflow.Input == Input {
        self.action = action
        self.specification = specification
        self.policy = policy
        self.state = state
    }
}
