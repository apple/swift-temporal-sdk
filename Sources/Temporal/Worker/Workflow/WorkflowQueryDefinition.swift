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

/// A protocol for defining Temporal workflow queries.
///
/// Workflow queries provide a way to synchronously retrieve information from a running workflow
/// without affecting its execution. Queries are read-only operations that can inspect the
/// current state of a workflow and return data to the caller.
///
/// ## Key Characteristics
///
/// - **Read-only**: Queries cannot modify workflow state or trigger side effects
/// - **Synchronous**: Queries return results immediately without workflow progression
/// - **Deterministic**: Query implementations must be deterministic and replay-safe
/// - **Stateless**: Queries should not depend on external state
///
/// ## Usage
///
/// ```swift
/// @Workflow
/// final class OrderProcessingWorkflow {
///     var currentStatus = "pending"
///
///     func run(input: OrderInput) async throws -> Void {
///         currentStatus = "processing"
///         // Process order logic
///         try await processOrder()
///         currentStatus = "finished"
///     }
///
///     @WorkflowQuery
///     func getOrderStatus() throws -> String {
///         return currentStatus
///     }
/// }
/// ```
public protocol WorkflowQueryDefinition<Workflow>: Sendable {
    /// The input type for the query.
    associatedtype Input: Sendable

    /// The output type returned by the query.
    associatedtype Output: Sendable

    /// The workflow type that this query can be applied to.
    ///
    /// This establishes the relationship between the query and its target workflow.
    associatedtype Workflow: WorkflowDefinition

    /// The query name used for identification and routing.
    ///
    /// This identifier is used by Temporal to route query requests to the appropriate implementation.
    /// Defaults to the string representation of the conforming type.
    static var name: String { get }

    /// An optional description of the query's purpose.
    ///
    /// This description may appear in user interfaces and tooling to help
    /// users understand the query's functionality. Defaults to `nil`.
    static var description: String? { get }

    /// Executes the query and returns the requested information.
    ///
    /// This method is called when a query request is received for the workflow.
    /// Use ``Workflow`` to access the workflow execution context.
    ///
    /// - Parameters:
    ///   - workflow: The workflow instance being queried.
    ///   - input: The input data for the query.
    /// - Returns: The query result.
    /// - Throws: Any error that occurs during query processing.
    func run(workflow: Workflow, input: Input) throws -> Output
}

extension WorkflowQueryDefinition {
    /// Default implementation returning the type name as the query name.
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
}
