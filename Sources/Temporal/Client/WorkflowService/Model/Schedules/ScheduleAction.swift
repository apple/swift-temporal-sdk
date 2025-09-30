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

/// Actions that can be executed when a schedule triggers.
public enum ScheduleAction<Input: Sendable>: Sendable {
    /// Configuration for scheduling workflow execution actions.
    public struct ActionStartWorkflow: Sendable {
        /// The name of the to to be scheduled workflow.
        public var workflowName: String

        /// The input data to pass to the scheduled workflow execution.
        public var input: Input

        /// The workflow execution options defining timeouts, retry policies, and task queue settings.
        public var options: WorkflowOptions

        /// Custom headers to include with the workflow execution.
        public var headers: [String: TemporalPayload]

        /// Creates a schedule action for starting workflow executions with input data.
        ///
        /// - Parameters:
        ///   - workflowName: The name of the workflow associated with this schedule.
        ///   - options: Workflow execution options including timeouts and retry policies.
        ///   - headers: Custom headers to include with workflow execution.
        ///   - input: The input data to pass to the workflow.
        public init(
            workflowName: String,
            options: WorkflowOptions,
            headers: [String: TemporalPayload] = [:],
            input: Input
        ) {
            self.workflowName = workflowName
            self.input = input
            self.options = options
            self.headers = headers
        }

        /// Creates a schedule action for starting workflow executions with input data.
        ///
        /// - Parameters:
        ///   - workflowName: The name of the workflow associated with this schedule.
        ///   - options: Workflow execution options including timeouts and retry policies.
        ///   - headers: Custom headers to include with workflow execution.
        public init(
            workflowName: String,
            options: WorkflowOptions,
            headers: [String: TemporalPayload] = [:]
        ) where Input == Void {
            self.init(workflowName: workflowName, options: options, headers: headers, input: ())
        }

        /// Creates a schedule action for starting workflow executions with input data.
        ///
        /// - Parameters:
        ///   - workflowType: The type of workflow to execute (typically inferred from context).
        ///   - options: Workflow execution options including timeouts and retry policies.
        ///   - headers: Custom headers to include with workflow execution.
        ///   - input: The input data to pass to the workflow.
        public init<Workflow: WorkflowDefinition>(
            workflowType: Workflow.Type = Workflow.self,
            options: WorkflowOptions,
            headers: [String: TemporalPayload] = [:],
            input: Workflow.Input
        ) where Workflow.Input == Input {
            self.init(
                workflowName: Workflow.name,
                options: options,
                headers: headers,
                input: input
            )
        }

        /// Creates a schedule action for starting workflow executions without input data.
        ///
        /// - Parameters:
        ///   - workflowType: The type of workflow to execute (typically inferred from context).
        ///   - options: Workflow execution options including timeouts and retry policies.
        ///   - headers: Custom headers to include with workflow execution.
        public init<Workflow: WorkflowDefinition>(
            workflowType: Workflow.Type = Workflow.self,
            options: WorkflowOptions,
            headers: [String: TemporalPayload] = [:],
        ) where Workflow.Input == Void, Workflow.Input == Input {
            self.init(workflowType: workflowType, options: options, headers: headers, input: ())
        }
    }

    /// Schedule action that starts a workflow execution when triggered.
    case startWorkflow(ActionStartWorkflow)
}
