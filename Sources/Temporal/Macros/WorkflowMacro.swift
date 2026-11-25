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
/// - Be a `struct`.
/// - Have a `mutating func run(context:input:)` method that returns the workflow result.
///
/// If the workflow doesn't declare an `init(input:)` initializer, the macro generates an empty one,
/// which requires all stored properties to have default values.
///
/// ## Usage
///
/// ```swift
/// @Workflow
/// struct GreetingWorkflow {
///     mutating func run(context: WorkflowContext<Self>, input: String) async throws -> String {
///         return try await context.executeActivity(
///             GreetingActivity.Activities.Greet.self,
///             options: .init(startToCloseTimeout: .seconds(30)),
///             input: input
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
/// The function must not return a value and must take an `input` parameter, optionally preceded by a
/// `context: WorkflowContext<Self>` parameter.
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
/// struct GreetingWorkflow {
///     var shouldGreet = false
///
///     mutating func run(context: WorkflowContext<Self>, input: String) async throws -> String {
///         try await context.condition { $0.shouldGreet }
///         return try await context.executeActivity(
///             GreetingActivity.Activities.Greet.self,
///             options: .init(startToCloseTimeout: .seconds(30)),
///             input: input
///         )
///     }
///
///     @WorkflowSignal
///     mutating func greet(input: Void) {
///         self.shouldGreet = true
///     }
/// }
/// ```
///
/// - Parameter name: The name of the signal. If not provided, defaults to the function name.
/// - Parameter description: An optional description of the signal's purpose.
/// - Parameter unfinishedPolicy: The policy for handling unfinished instances of this handler when
///   the workflow exits. Defaults to ``HandlerUnfinishedPolicy/warnAndAbandon``.
@attached(peer, names: arbitrary)
public macro WorkflowSignal(name: String? = nil, description: String? = nil, unfinishedPolicy: HandlerUnfinishedPolicy = .warnAndAbandon) =
    #externalMacro(module: "TemporalMacros", type: "WorkflowSignalMacro")

/// Defines a query handler for a workflow.
///
/// The `@WorkflowQuery` macro marks a function as a query handler within a workflow.
/// Queries are synchronous, read-only requests that can be sent to a running workflow
/// to retrieve current state information without modifying the workflow execution.
///
/// The function must return a non-`Void` value and must take an `input` parameter, optionally preceded by a
/// `context: WorkflowContextView` parameter.
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
/// Use on a method to define a query:
///
/// ```swift
/// @Workflow
/// struct GreetingWorkflow {
///     var name: String = ""
///
///     mutating func run(context: WorkflowContext<Self>, input: String) async throws -> String {
///         self.name = input
///         try await context.condition { $0.name == "done" }
///         return name
///     }
///
///     @WorkflowQuery
///     func greetName(input: Void) -> String {
///         self.name
///     }
/// }
/// ```
/// Use on stored or computed properties to directly expose it as a query. The property needs an explicit type annotation:
///
/// ```swift
/// @Workflow
/// struct OrderWorkflow {
///     @WorkflowQuery
///     var status: String = "pending"
/// }
/// ```
///
/// - Parameter name: The name of the query. If not provided, defaults to the function or property name.
/// - Parameter description: An optional description of the query's purpose.
@attached(peer, names: arbitrary)
public macro WorkflowQuery(name: String? = nil, description: String? = nil) = #externalMacro(module: "TemporalMacros", type: "WorkflowQueryMacro")

/// Defines an update handler for a workflow.
///
/// The `@WorkflowUpdate` macro marks a function as an update handler within a workflow.
/// Updates are synchronous requests that can modify workflow state and return a result,
/// combining the immediacy of queries with the state-modification capabilities of signals.
///
/// The function must take an `input` parameter, optionally preceded by a `context: WorkflowContext<Self>` parameter.
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
/// struct GreetingWorkflow {
///     var shouldGreet = false
///     var name = ""
///
///     mutating func run(context: WorkflowContext<Self>, input: String) async throws -> String {
///         self.name = input
///         try await context.condition { $0.shouldGreet }
///         return try await context.executeActivity(
///             GreetingActivity.Activities.Greet.self,
///             options: .init(startToCloseTimeout: .seconds(30)),
///             input: input
///         )
///     }
///
///     @WorkflowUpdate
///     mutating func greet(input: Void) async throws -> String {
///         self.shouldGreet = true
///         return self.name
///     }
/// }
/// ```
///
/// - Parameter name: The name of the update. If not provided, defaults to the function name.
/// - Parameter description: An optional description of the update's purpose.
/// - Parameter unfinishedPolicy: The policy for handling unfinished instances of this handler when
///   the workflow exits. Defaults to ``HandlerUnfinishedPolicy/warnAndAbandon``.
/// - Parameter validator: The name of a method on the workflow type that validates the update input
///   before execution. The validator method must be synchronous, have a single parameter called `input` of the
///   same type as the update handler's input, and return `Void`. It may throw to reject the update. If not provided,
///   no validation is performed.
@attached(peer, names: arbitrary)
public macro WorkflowUpdate(
    name: String? = nil,
    description: String? = nil,
    unfinishedPolicy: HandlerUnfinishedPolicy = .warnAndAbandon,
    validator: String? = nil
) =
    #externalMacro(module: "TemporalMacros", type: "WorkflowUpdateMacro")

/// Makes workflow state sendable by ensuring it is modified on the workflow's executor.
///
/// `_WorkflowState` ensures that all modifications to workflow state happen safely within
/// the workflow's execution context. It enforces that state can only be accessed and
/// modified on the workflow's dedicated executor, preventing race conditions and ensuring
/// deterministic execution during workflow replay.
///
/// ## Usage
///
/// The `@Workflow` macro automatically applies the `@_WorkflowState` macro to all mutable, stored instance properties:
///
/// ```swift
/// @Workflow
/// struct IncrementingWorkflow {
///     private var state = 1
///
///     mutating func run(context: WorkflowContext<Self>, input: Void) async throws -> Int {
///         await withTaskGroup { group in
///             group.addTask {
///                 context.mutateState { $0.state += 1 }
///             }
///             group.addTask {
///                 context.mutateState { $0.state += 1 }
///             }
///         }
///         return self.state
///     }
/// }
/// ```
///
/// > Note: Code running outside of `run` and the handlers, like the child tasks above, modifies the state through
/// > ``WorkflowContext/mutateState(_:)``.
@attached(accessor, names: named(init), named(get), named(set))
@attached(peer, names: prefixed(_))
public macro _WorkflowState() = #externalMacro(module: "TemporalMacros", type: "WorkflowStateMacro")
