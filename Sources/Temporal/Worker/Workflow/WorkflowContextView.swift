//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Temporal SDK open source project
//
// Copyright (c) 2026 Apple Inc. and the Swift Temporal SDK project authors
// Licensed under MIT License
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Swift Temporal SDK project authors
//
// SPDX-License-Identifier: MIT
//
//===----------------------------------------------------------------------===//

public import struct Foundation.Date

/// A read-only context for queries, validators, and sync handlers.
///
/// `WorkflowContextView` provides access to live workflow metadata and state machine
/// reads, but does not expose any command methods or state mutation capabilities.
/// This ensures compile-time safety: queries and validators cannot issue commands
/// or modify workflow state.
///
/// ## Available Information
///
/// - Static workflow metadata via ``info``
/// - Live state machine reads: ``now``, ``isReplaying``, ``searchAttributes``, etc.
/// - Raw randomness seed (but not the stateful RNG)
///
/// ## Not Available
///
/// - No command methods (sleep, executeActivity, etc.)
/// - No state mutation
/// - No stateful random number generator
public struct WorkflowContextView: @unchecked Sendable {
    /// The underlying state machine storage.
    private let storage: WorkflowStateMachineStorage

    /// Information about the current workflow execution.
    public let info: WorkflowInfo

    /// Creates a new workflow context view.
    ///
    /// - Parameters:
    ///   - storage: The workflow state machine storage.
    ///   - info: The workflow info.
    package init(storage: WorkflowStateMachineStorage, info: WorkflowInfo) {
        self.storage = storage
        self.info = info
    }

    /// The current date of the workflow.
    ///
    /// This value is deterministic and safe for replays.
    public var now: Date {
        storage.now()
    }

    /// A Boolean value that indicates whether the workflow is currently in replay mode.
    public var isReplaying: Bool {
        storage.isReplaying()
    }

    /// The current search attributes for the workflow.
    public var searchAttributes: SearchAttributeCollection {
        storage.searchAttributes()
    }

    /// The current worker deployment version for this task.
    public var currentDeploymentVersion: DeploymentVersion? {
        storage.currentDeploymentVersion()
    }

    /// A Boolean value that indicates whether continue as new was suggested.
    public var continueAsNewSuggested: Bool {
        storage.continueAsNewSuggested()
    }

    /// The reasons why continue-as-new is suggested.
    ///
    /// When the server detects that a workflow's state is growing too large,
    /// it provides one or more reasons indicating why a continue-as-new is recommended.
    /// This array is empty when ``continueAsNewSuggested`` is `false`.
    ///
    /// - Important: This is currently experimental and may be removed or changed in the future.
    public var suggestContinueAsNewReasons: [SuggestContinueAsNewReason] {
        storage.suggestContinueAsNewReasons()
    }

    /// Current number of events in the history.
    public var currentHistoryLength: Int {
        storage.currentHistoryLength()
    }

    /// Current size of the history in bytes.
    public var currentHistorySize: Int {
        storage.currentHistorySize()
    }

    /// A Boolean value that indicates whether all update and signal handlers have finished executing.
    public var allHandlersFinished: Bool {
        storage.allHandlersFinished()
    }

    /// User specified details for this workflow that may appear in UI/CLI.
    public var currentDetails: String? {
        storage.currentDetails()
    }

    /// Information about the currently executing update, if any.
    public var currentUpdateInfo: WorkflowUpdateInfo? {
        InternalWorkflowContext.currentUpdateInfo
    }
}
