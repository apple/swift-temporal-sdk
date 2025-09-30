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

/// Defines a Temporal workflow type.
///
/// The `@Workflow` macro automatically generates the necessary conformance to ``WorkflowDefinition``
/// and creates implementations for signals, queries, and updates defined within the workflow type.
///
/// It enables workflows to use `@WorkflowSignal`, `@WorkflowUpdate`, and `@WorkflowQuery` macros
/// for defining workflow handlers.
///
/// ## Requirements
///
/// Workflows must:
/// - Be a `final class`.
/// - Have a `run(input:)` method that returns the workflow result.
///
/// ## Usage
///
/// ```swift
/// @Workflow
/// final class GreetingWorkflow {
///     func run(context: WorkflowContext, input: String) async throws -> String {
///         return try await executeActivity(
///             GreetingActivity.self,
///             input: name
///         )
///     }
/// }
/// ```
/// - Parameter name: The name of the workflow. If not provided, defaults to the type name.
@attached(extension, conformances: WorkflowDefinition, names: arbitrary)
@attached(member, names: named(signals), named(queries), named(updates), named(init))
@attached(memberAttribute)
public macro Workflow(name: String? = nil) = #externalMacro(module: "TemporalMacros", type: "WorkflowMacro")

/// Defines a signal handler for a workflow.
///
/// The `@WorkflowSignal` macro marks a function as a signal handler within a workflow.
/// Signals are asynchronous messages that can be sent to a running workflow.
///
/// ## Key Characteristics
///
/// - **Asynchronous**: Signals are sent without waiting for execution completion
/// - **Non-blocking**: Signal handlers execute alongside the main workflow logic
/// - **Persistent**: Signals are queued if the workflow is not immediately available
/// - **Deterministic**: Signal handlers must be deterministic and replay-safe
///
/// ## Usage
///
/// ```swift
/// @Workflow
/// final class GreetingWorkflow {
///     var shouldGreet: false
///
///     func run(context: WorkflowContext, input: String) async throws -> String {
///         try await Workflow.condition { self.shouldGreet }
///         return try await executeActivity(
///             GreetingActivity.self,
///             input: name
///         )
///     }
///
///     @WorkflowSignal
///     func greet() {
///         self.shouldGreet = true
///     }
/// }
/// ```
///
/// - Parameter name: The name of the signal. If not provided, defaults to the function name.
/// - Parameter description: An optional description of the signal's purpose.
@attached(peer, names: arbitrary)
public macro WorkflowSignal(name: String? = nil, description: String? = nil) = #externalMacro(module: "TemporalMacros", type: "WorkflowSignalMacro")

/// Defines a query handler for a workflow.
///
/// The `@WorkflowQuery` macro marks a function as a query handler within a workflow.
/// Queries are synchronous, read-only requests that can be sent to a running workflow
/// to retrieve current state information without modifying the workflow execution.
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
/// final class GreetingWorkflow {
///     var name: String
///
///     func run(context: WorkflowContext, input: String) async throws -> String {
///         self.name = name
///         return try await executeActivity(
///             GreetingActivity.self,
///             input: name
///         )
///     }
///
///     @WorkflowQuery
///     func greetName() -> String {
///         self.name
///     }
/// }
/// ```
/// - Parameter name: The name of the query. If not provided, defaults to the function name.
/// - Parameter description: An optional description of the query's purpose.
@attached(peer, names: arbitrary)
public macro WorkflowQuery(name: String? = nil, description: String? = nil) = #externalMacro(module: "TemporalMacros", type: "WorkflowQueryMacro")

/// Defines an update handler for a workflow.
///
/// The `@WorkflowUpdate` macro marks a function as an update handler within a workflow.
/// Updates are synchronous requests that can modify workflow state and return a result,
/// combining the immediacy of queries with the state-modification capabilities of signals.
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
/// final class GreetingWorkflow {
///     var shouldGreet: false
///     var name: String
///
///     func run(context: WorkflowContext, input: String) async throws -> String {
///         self.name = name
///         try await Workflow.condition { self.shouldGreet }
///         return try await executeActivity(
///             GreetingActivity.self,
///             input: name
///         )
///     }
///
///     @WorkflowUpdate
///     func greet() async throws -> String {
///         self.shouldGreet = true
///         return self.name
///     }
/// }
/// ```
///
/// - Parameter name: The name of the update. If not provided, defaults to the function name.
/// - Parameter description: An optional description of the update's purpose.
@attached(peer, names: arbitrary)
public macro WorkflowUpdate(name: String? = nil, description: String? = nil) = #externalMacro(module: "TemporalMacros", type: "WorkflowUpdateMacro")

/// Makes workflow state sendable by ensuring it is modified on the workflow's executor.
///
/// `_WorkflowState` ensures that all modifications to workflow state happen safely within
/// the workflow's execution context. It enforces that state can only be accessed and
/// modified on the workflow's dedicated executor, preventing race conditions and ensuring
/// deterministic execution during workflow replay.
///
/// ## Usage
///
/// The `@Workflow` macro automatically applies the `@_WorkflowState` macro to all members:
///
/// ```swift
/// @Workflow
/// final class IncrementingWorkflow {
///     private var state = 1
///
///     func run(input: Void) async throws -> Int {
///         await withTaskGroup { group in
///             group.addTask {
///                 self.state += 1
///             }
///             group.addTask {
///                 self.state += 1
///             }
///         }
///         return self.state
///     }
/// }
/// ```
@attached(accessor, names: named(init), named(get), named(set))
@attached(peer, names: prefixed(_))
public macro _WorkflowState() = #externalMacro(module: "TemporalMacros", type: "WorkflowStateMacro")
