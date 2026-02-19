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

import SwiftProtobuf

public import struct Foundation.Date

/// Information about a specific workflow execution instance.
///
/// This structure provides comprehensive metadata about a workflow execution,
/// including its current state, timing information, and associated data.
/// It represents a snapshot of the workflow execution at a particular point in time.
///
/// ## Usage
///
/// Workflow execution information is typically obtained through client APIs:
///
/// ```swift
/// let execution = try await client.describeWorkflowExecution(
///     workflowID: "my-workflow-123",
///     runID: nil
/// )
/// print("Workflow Type: \(execution.workflowType)")
/// print("Status: \(execution.status)")
/// print("History Length: \(execution.historyLength)")
/// ```
public struct WorkflowExecution: Hashable, Sendable {
    /// The workflow type name for this execution.
    ///
    /// This identifies the specific workflow implementation that was used
    /// to create this execution instance.
    public var workflowType: String

    /// The unique workflow identifier.
    ///
    /// This ID remains constant across all attempts and retries of the same
    /// workflow execution instance.
    public var workflowID: String

    /// The workflow ID of the parent workflow if this is a child workflow.
    ///
    /// This value is `nil` for root workflows and contains the parent's
    /// workflow ID for child workflow executions.
    public var parentWorkflowID: String?

    /// The unique run identifier for this workflow execution.
    ///
    /// This ID changes for each retry or continuation of the workflow.
    public var runID: String

    /// The run ID of the parent workflow if this is a child workflow.
    ///
    /// This value is `nil` for root workflows and contains the parent's
    /// run ID for child workflow executions.
    public var parentRunID: String?

    /// The task queue where this workflow is executing.
    ///
    /// Task queues are used to route workflow and activity tasks to appropriate workers.
    public var taskQueue: String

    /// The timestamp when this workflow execution was created.
    ///
    /// This represents the time when the workflow was first scheduled.
    public var startTime: Date

    /// The timestamp when this workflow execution was closed.
    ///
    /// This value is `nil` for running workflows and contains the close time
    /// for completed, failed, or terminated workflows.
    public var closeTime: Date?

    /// The timestamp when the workflow execution should start or did start.
    ///
    /// This may differ from `startTime` for scheduled workflows that have
    /// a delayed start time.
    public var executionTime: Date?

    /// The total number of events in the workflow execution's history.
    ///
    /// This count includes all events from workflow start to the current state,
    /// providing insight into the workflow's complexity and progress.
    public var historyLength: Int

    /// User-defined memo data associated with this workflow execution.
    ///
    /// Memos are key-value pairs that can be used to store additional
    /// metadata about the workflow execution.
    public var memo: [String: TemporalRawValue]

    /// Search attributes associated with this workflow execution.
    ///
    /// Search attributes enable indexing and querying of workflow executions
    /// through Temporal's visibility APIs.
    public var searchAttributes: SearchAttributeCollection

    /// Creates a workflow execution instance from Temporal API data.
    ///
    /// - Parameters:
    ///   - raw: The raw workflow execution info from the Temporal API.
    ///   - dataConverter: Data converter for deserializing memo and search attributes.
    /// - Throws: Any error that occurs during data conversion.
    init(_ raw: Api.Workflow.V1.WorkflowExecutionInfo, dataConverter: DataConverter) throws {
        workflowType = raw.type.name
        workflowID = raw.execution.workflowID
        parentWorkflowID = raw.hasParentExecution ? raw.parentExecution.workflowID : nil
        runID = raw.execution.runID
        parentRunID = raw.hasParentExecution ? raw.parentExecution.runID : nil
        taskQueue = raw.taskQueue
        startTime = raw.startTime.date
        closeTime = raw.hasCloseTime ? raw.closeTime.date : nil
        executionTime = raw.hasExecutionTime ? raw.executionTime.date : nil
        historyLength = Int(raw.historyLength)
        searchAttributes = try .init(raw.searchAttributes)
        memo = raw.memo.fields.mapValues { .init(.init(temporalAPIPayload: $0)) }
    }
}
