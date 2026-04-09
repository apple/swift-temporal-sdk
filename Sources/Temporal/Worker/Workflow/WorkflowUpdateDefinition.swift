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

/// A protocol for defining Temporal workflow updates.
///
/// Workflow updates provide a way to synchronously modify workflow state and receive a response.
/// Unlike signals, updates are request-response operations that can return values to the caller
/// and provide stronger consistency guarantees.
///
/// ## Key Characteristics
///
/// - **Synchronous**: Updates wait for completion and return results
/// - **Transactional**: Updates are processed atomically with workflow state
/// - **Validated**: Updates can include validation logic before execution
/// - **Deterministic**: Update handlers must be deterministic and replay-safe
///
/// ## Usage
///
/// ```swift
/// @Workflow
/// struct OrderProcessingWorkflow {
///     var orderItems: [OrderItem] = []
///     var currentStatus: OrderStatus = .pending
///
///     mutating func run(context: WorkflowContext<Self>, input: OrderInput) async throws -> OrderResult {
///         self.currentStatus = .processing
///         return try await context.executeActivity(
///             ProcessOrderActivity.self,
///             options: .init(startToCloseTimeout: .seconds(30)),
///             input: input
///         )
///     }
///
///     @WorkflowUpdate
///     mutating func changeStatus(context: WorkflowContext<Self>, input: OrderStatus) async throws -> OrderStatus {
///         let previousStatus = currentStatus
///         self.currentStatus = input
///         return previousStatus
///     }
/// }
/// ```
public protocol WorkflowUpdateDefinition<Workflow>: Sendable {
    /// The input type for the update.
    associatedtype Input: Sendable

    /// The output type returned by the update.
    associatedtype Output: Sendable

    /// The workflow type that this update can be applied to.
    associatedtype Workflow: WorkflowDefinition

    /// The update name used for identification and routing.
    ///
    /// This identifier is used by Temporal to route update requests to the appropriate implementation.
    /// Defaults to the string representation of the conforming type.
    static var name: String { get }

    /// An optional description of the update's purpose.
    ///
    /// This description may appear in user interfaces and tooling to help
    /// users understand the update's functionality. Defaults to `nil`.
    static var description: String? { get }

    /// The policy for handling unfinished instances of this handler when the workflow exits.
    ///
    /// This controls what happens when the workflow completes (successfully, with failure,
    /// cancellation, or continue-as-new) while this update handler is still running.
    /// Defaults to ``HandlerUnfinishedPolicy/warnAndAbandon``.
    static var unfinishedPolicy: HandlerUnfinishedPolicy { get }

    /// Validates the update input before execution.
    ///
    /// This method is called before the update is executed to validate the input data
    /// and ensure the workflow is in an appropriate state to handle the update.
    /// Throwing an error from this method rejects the update.
    ///
    /// - Parameters:
    ///   - workflow: The workflow instance being updated.
    ///   - input: The input data to validate.
    /// - Throws: Any validation error that should prevent update execution.
    func validateInput(workflow: Workflow, _ input: Input) throws

    /// Executes the update and returns the result.
    ///
    /// This method is called when an update request is received for the workflow.
    ///
    /// - Parameters:
    ///   - workflow: The workflow instance being updated.
    ///   - context: The workflow execution context.
    ///   - input: The input data for the update.
    /// - Returns: The update result.
    /// - Throws: Any error that occurs during update processing.
    func run(workflow: Workflow, context: WorkflowContext<Workflow>, input: Input) async throws -> Output
}

extension WorkflowUpdateDefinition {
    /// Default implementation returning the type name as the update name.
    public static var name: String {
        String(describing: self)
    }

    /// Instance property providing access to the static name.
    var name: String {
        Self.name
    }

    /// Default implementation with no description.
    public static var description: String? { nil }

    /// Instance property providing access to the static description.
    var description: String? {
        Self.description
    }

    /// Default implementation returning ``HandlerUnfinishedPolicy/warnAndAbandon``.
    public static var unfinishedPolicy: HandlerUnfinishedPolicy { .warnAndAbandon }

    /// Instance property providing access to the static unfinished policy.
    var unfinishedPolicy: HandlerUnfinishedPolicy {
        Self.unfinishedPolicy
    }

    /// Default implementation that performs no validation.
    ///
    /// Override this method to provide custom validation logic for update inputs.
    public func validateInput(workflow: Workflow, _ input: Input) throws {}
}
