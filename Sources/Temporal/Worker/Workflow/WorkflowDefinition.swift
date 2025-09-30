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

/// A protocol defining a Temporal workflow implementation.
///
/// Workflows orchestrate the execution of activities and other workflows, providing durable execution
/// guarantees across failures and maintaining state throughout their lifecycle.
///
/// ## Key characteristics
///
/// - **Deterministic**: Workflow code must be deterministic to support replay-based recovery
/// - **Durable**: Workflow state persists across worker restarts and failures
/// - **Versioned**: Workflows support versioning for backward compatibility
/// - **Long-running**: Workflows can execute for extended periods (days, months, or years)
///
/// ## Usage
///
/// ```swift
/// @Workflow
/// final class OrderProcessingWorkflow: WorkflowDefinition {
///     let orderRequest: OrderRequest
///
///     init(input: OrderRequest) {
///         self.orderRequest = input
///     }
///
///     func run(input: OrderRequest) async throws -> OrderResult {
///         // Use Workflow static methods to perform workflow operations
///         let result = try await Workflow.executeActivity(
///             activityType: ProcessOrderActivity.self,
///             options: .init(startToCloseTimeout: .seconds(30)),
///             input: orderRequest
///         )
///         return result
///     }
/// }
/// ```
public protocol WorkflowDefinition: Sendable {
    /// The workflow's input type.
    associatedtype Input: Sendable

    /// The workflow's output type.
    associatedtype Output: Sendable

    /// The workflow name used for registration and execution.
    ///
    /// This identifier is used by Temporal to route workflow execution requests to the appropriate implementation.
    /// Defaults to the string representation of the conforming type.
    static var name: String { get }

    /// The signal definitions supported by this workflow.
    ///
    /// Signals are asynchronous messages that can be sent to a running workflow to trigger
    /// specific behavior or state changes. Defaults to an empty array.
    static var signals: [any WorkflowSignalDefinition<Self>] { get }

    /// The query definitions supported by this workflow.
    ///
    /// Queries are synchronous, read-only requests that can be sent to a running workflow
    /// to retrieve current state information. Defaults to an empty array.
    static var queries: [any WorkflowQueryDefinition<Self>] { get }

    /// The update definitions supported by this workflow.
    ///
    /// Updates are synchronous requests that can modify workflow state and return a result.
    /// Defaults to an empty array.
    static var updates: [any WorkflowUpdateDefinition<Self>] { get }

    /// Initializes a new workflow instance.
    ///
    /// This initializer is called by the Temporal SDK when a new workflow execution is started.
    /// Use this method to set up initial workflow state based on the provided input.
    ///
    /// - Parameter input: The input data for the workflow execution.
    init(input: Input)

    /// Executes the workflow logic.
    ///
    /// This method contains the core workflow implementation and defines the orchestration
    /// of activities, child workflows, and other workflow operations.
    /// Use ``Workflow`` to access the workflow execution context.
    ///
    /// - Parameter input: The workflow input.
    /// - Returns: The workflow execution result.
    /// - Throws: Any error that causes the workflow to fail.
    func run(input: Input) async throws -> Output
}

extension WorkflowDefinition {
    public static var name: String {
        String(describing: self)
    }

    public static var signals: [any WorkflowSignalDefinition<Self>] {
        []
    }

    public static var queries: [any WorkflowQueryDefinition<Self>] {
        []
    }

    public static var updates: [any WorkflowUpdateDefinition<Self>] {
        []
    }
}
