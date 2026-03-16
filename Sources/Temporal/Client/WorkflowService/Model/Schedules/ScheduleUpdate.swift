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

/// Contains schedule configuration changes for update operations.
public struct ScheduleUpdate<Input: Sendable>: Sendable {
    /// The complete schedule configuration to apply as the update.
    public var schedule: Schedule<Input>

    /// Optional indexed attributes that can be used while querying schedules via the list
    /// schedules APIs.
    ///
    /// The key and value type must be registered with Temporal server.
    ///
    /// - If `nil`, the search attributes will not be updated.
    /// - If present but empty, the search attributes will be cleared.
    /// - If present and non-empty, all search attributes will be updated to the provided
    ///   collection. This means existing attributes which do not exist in the provided collection
    ///   will be removed. You can copy attributes from the existing ``ScheduleDescription``
    ///   to avoid this.
    public var searchAttributes: SearchAttributeCollection?

    /// Creates a schedule update with the specified configuration changes.
    ///
    /// - Parameters:
    ///   - schedule: The complete schedule configuration to apply.
    ///   - searchAttributes: Optional search attributes to update. If `nil`, search attributes are
    ///     not changed.
    public init(
        schedule: Schedule<Input>,
        searchAttributes: SearchAttributeCollection? = nil
    ) {
        self.schedule = schedule
        self.searchAttributes = searchAttributes
    }

    /// Creates a schedule update with the specified configuration changes.
    ///
    /// - Parameters:
    ///    - workflowType: The workflow type associated with this schedule update.
    ///    - schedule: The complete schedule configuration to apply.
    ///    - searchAttributes: Optional search attributes to update. If `nil`, search attributes are
    ///      not changed.
    public init<Workflow: WorkflowDefinition>(
        workflowType: Workflow.Type = Workflow.self,
        schedule: Schedule<Workflow.Input>,
        searchAttributes: SearchAttributeCollection? = nil
    ) where Workflow.Input == Input {
        self.schedule = schedule
        self.searchAttributes = searchAttributes
    }
}
