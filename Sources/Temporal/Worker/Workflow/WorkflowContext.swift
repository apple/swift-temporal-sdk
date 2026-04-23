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

public import Logging

public import struct Foundation.Date

/// The workflow context providing access to Temporal workflow operations.
///
/// `WorkflowContext` is the primary interface through which workflows interact with the
/// Temporal system. It provides instance methods for all workflow operations including
/// activity execution, child workflow management, timers, conditions, and workflow state
/// management.
///
/// ## Deterministic execution
///
/// All operations performed through the `WorkflowContext` API are deterministic and replay-safe.
/// The API ensures that workflow executions are consistent across retries and replay scenarios.
///
/// ## Usage
///
/// The `WorkflowContext` is passed as a parameter to the workflow's `run` method and
/// signal/update handlers:
///
/// ```swift
/// mutating func run(context: WorkflowContext<Self>, input: MyInput) async throws -> MyOutput {
///     // Execute an activity
///     let result = try await context.executeActivity(
///         MyActivity.self,
///         options: .init(startToCloseTimeout: .seconds(30)),
///         input: "hello"
///     )
///
///     // Sleep for a duration
///     try await context.sleep(for: .seconds(5))
///
///     // Wait for a condition
///     try await context.condition { someState == expectedValue }
///
///     return result
/// }
/// ```
///
/// - Important: This type is only valid for use within the scope of a workflow execution.
public struct WorkflowContext<Workflow: WorkflowDefinition>: @unchecked Sendable {
    let internalContext: InternalWorkflowContext
    let stateBox: ArcBox<Workflow>

    init(internalContext: InternalWorkflowContext, stateBox: ArcBox<Workflow>) {
        self.internalContext = internalContext
        self.stateBox = stateBox
    }

    // MARK: - State Access

    /// Mutates the workflow state using a closure and returns a value.
    ///
    /// Normally you can just mutate the state of the workflow by making your run method or the handler
    /// mutating. However, you cannot capture `self` in escaping closures such as async let's or
    /// child tasks. This method allows you to mutate the state safely in such closures.
    ///
    /// ## Usage
    ///
    /// ```swift
    /// @WorkflowSignal
    /// func addItem(context: WorkflowContext<Self>, input: Item) async throws {
    ///     async let execute = {
    ///         context.mutateState { workflow in
    ///             workflow.items.append(input)
    ///         }
    ///         try await context.executeActivity(
    ///             PersistItemActivity.self,
    ///             options: .init(startToCloseTimeout: .seconds(10)),
    ///             input: input
    ///         )
    ///     }
    ///     try await execute
    /// }
    /// ```
    ///
    /// - Parameter mutator: A closure that receives a mutable reference to the workflow struct
    ///   and returns a value.
    /// - Returns: The value returned by the closure.
    public func mutateState<Return>(_ mutator: (inout Workflow) -> Return) -> Return {
        stateBox.withMutableValue(mutator)
    }

    /// A Boolean value that indicates whether the current code is executing within a workflow context.
    public static var inWorkflow: Bool {
        InternalWorkflowContext.current != nil
    }

    /// Information about the currently executing update, if any.
    ///
    /// Returns the update ID and name when called from within an update handler
    /// or update validator. Returns `nil` when called outside of an update context
    /// (e.g., from the main workflow run method, signal handlers, or query handlers).
    public var currentUpdateInfo: WorkflowUpdateInfo? {
        InternalWorkflowContext.currentUpdateInfo
    }

    /// The current worker deployment version for this task.
    ///
    /// May be unset if the task was completed by a worker without a deployment version or build id.
    /// If this worker is the one executing this task for the first time and has a deployment version set,
    /// then its ID will be used. This value may change over the lifetime of the workflow run, but is
    /// deterministic and safe to use for branching.
    public var currentDeploymentVersion: DeploymentVersion? {
        self.internalContext.currentDeploymentVersion
    }

    /// Information about the current workflow execution.
    ///
    /// Provides access to workflow metadata including identifiers, timing information,
    /// configuration, and parent workflow details.
    public var info: WorkflowInfo {
        self.internalContext.info
    }

    /// The data converter used for payload serialization and deserialization.
    ///
    /// This converter handles the transformation between Swift types and Temporal's
    /// internal payload format.
    public var payloadConverter: any PayloadConverter {
        self.internalContext.payloadConverter
    }

    /// A deterministic random number generator for workflow use.
    ///
    /// This generator ensures that random number generation is deterministic and replay-safe
    /// within workflow executions. The same sequence of random numbers will be generated
    /// during replay.
    ///
    /// ## Usage
    ///
    /// ```swift
    /// var rng = context.randomNumberGenerator
    /// let randomValue = Int.random(in: 1...100, using: &rng)
    /// ```
    public var randomNumberGenerator: any RandomNumberGenerator {
        self.internalContext.randomNumberGenerator
    }

    /// Indicates whether all update and signal handlers have finished executing.
    ///
    /// This property is useful for ensuring that all asynchronous handlers complete
    /// before the workflow terminates or continues as new. Waiting on this condition
    /// prevents interruption of in-progress handlers.
    ///
    /// ## Usage
    ///
    /// ```swift
    /// mutating func run(context: WorkflowContext<Self>, input: Void) async throws {
    ///     // Perform workflow logic...
    ///
    ///     // Wait for all handlers to finish before returning
    ///     try await context.condition { context.allHandlersFinished }
    /// }
    /// ```
    ///
    /// A Boolean value that indicates whether all handlers have finished.
    public var allHandlersFinished: Bool {
        self.internalContext.allHandlersFinished
    }

    /// The current date of the workflow.
    ///
    /// This value is deterministic and safe for replays.
    /// Do not use any other sources of system time in workflows.
    public var now: Date {
        self.internalContext.now
    }

    /// Indicates whether the workflow is currently in replay mode.
    package var isReplaying: Bool {
        self.internalContext.isReplaying
    }

    /// The current search attributes for the workflow.
    ///
    /// Search attributes are key-value pairs that can be used to index and query
    /// workflow executions. They are searchable through Temporal's visibility APIs.
    public var searchAttributes: SearchAttributeCollection {
        self.internalContext.searchAttributes
    }

    /// User specified details for this workflow that may appear in UI/CLI.
    ///
    /// Unlike static details set at start, this value can be updated throughout the life of the workflow.
    /// This can be in Temporal markdown format and can span multiple lines.
    ///
    /// - Important: This is currently experimental.
    public var currentDetails: String? {
        get { self.internalContext.currentDetails }
        nonmutating set {
            // Use the internal method since the context struct is immutable
            self.internalContext.updateCurrentDetails(newValue)
        }
    }

    /// A Boolean value that indicates whether continue as new was suggested.
    public var continueAsNewSuggested: Bool {
        self.internalContext.continueAsNewSuggested
    }

    /// The reasons why continue-as-new is suggested.
    ///
    /// When the server detects that a workflow's state is growing too large,
    /// it provides one or more reasons indicating why a continue-as-new is recommended.
    /// This array is empty when ``continueAsNewSuggested`` is `false`.
    ///
    /// - Important: This is currently experimental and may be removed or changed in the future.
    public var suggestContinueAsNewReasons: [SuggestContinueAsNewReason] {
        self.internalContext.suggestContinueAsNewReasons
    }

    /// Current number of events in the history.
    public var currentHistoryLength: Int {
        self.internalContext.currentHistoryLength
    }

    /// Current size of the history in bytes.
    public var currentHistorySize: Int {
        self.internalContext.currentHistorySize
    }

    /// The logger used for the workflow execution.
    public var logger: Logger {
        self.internalContext.logger
    }

    /// Updates or inserts the specified search attributes.
    ///
    /// Search attributes allow workflows to be indexed and queried through Temporal's
    /// visibility APIs. This method updates existing attributes or adds new ones.
    ///
    /// ## Usage
    ///
    /// ```swift
    /// var attributes = SearchAttributeCollection()
    /// attributes[.customStringField("order_status")] = "processing"
    /// attributes[.customIntField("priority")] = 5
    /// context.upsertSearchAttributes(attributes)
    /// ```
    ///
    /// - Parameter searchAttributes: The search attributes to update or insert.
    ///   Specify `nil` for a specific attribute to unset it.
    public func upsertSearchAttributes(_ searchAttributes: SearchAttributeCollection) {
        self.internalContext.upsertSearchAttributes(searchAttributes)
    }

    /// Updates or inserts search attributes using a builder block.
    ///
    /// This convenience method allows for fluent construction of search attribute updates.
    ///
    /// - Parameter builder: A closure that receives a mutable search attribute collection
    ///   to configure. Specify `nil` for specific attributes to unset them.
    ///
    /// ## Usage
    ///
    /// ```swift
    /// context.upsertSearchAttributes { attributes in
    ///     attributes[.customStringField("status")] = "completed"
    ///     attributes[.customIntField("score")] = 100
    ///     attributes[.customStringField("old_field")] = nil // Unset
    /// }
    /// ```
    public func upsertSearchAttributes(builder: (inout SearchAttributeCollection) -> Void) {
        var searchAttributes = SearchAttributeCollection()
        builder(&searchAttributes)
        upsertSearchAttributes(searchAttributes)
    }

    /// Sleep in a workflow for the given time.
    ///
    /// ## Usage
    ///
    /// ```swift
    /// // Sleep for 5 seconds
    /// try await context.sleep(for: .seconds(5))
    ///
    /// // Sleep with a summary for debugging
    /// try await context.sleep(for: .minutes(1), summary: "waiting for external system")
    /// ```
    ///
    /// - Parameter duration: The duration to sleep for.
    /// - Parameter summary: A simple string identifying this timer.
    public func sleep(for duration: Duration, summary: String? = nil) async throws {
        try await self.internalContext.sleep(for: duration, summary: summary)
    }

    /// Runs a closure until a timeout is reached.
    ///
    /// This is backed by ``sleep(for:summary:)``. Additionally, this method will always return
    /// the result of the `body` closure. When the timeout is hit the task in which the body
    /// closure runs will get cancelled and subsequently awaited until it returns.
    ///
    /// This means that whatever error is thrown by the `body` closure on task cancellation will
    /// be re-thrown by this method.
    ///
    /// ## Usage
    ///
    /// ```swift
    /// // Run an operation with a 30-second timeout
    /// let result = try await context.timeout(for: .seconds(30)) {
    ///     return try await performLongRunningOperation()
    /// }
    ///
    /// // Handle timeout by catching cancellation in the body
    /// let result = try await context.timeout(for: .minutes(2)) {
    ///     do {
    ///         return try await externalServiceCall()
    ///     } catch is CancellationError {
    ///         // Handle timeout gracefully
    ///         return defaultValue
    ///     }
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - duration: The duration for the timeout.
    ///   - body: The closure to run with a given timeout.
    /// - Returns: The result of the closure.
    public func timeout<Return: Sendable, Failure: Error>(
        for duration: Duration,
        body: @Sendable @escaping () async throws(Failure) -> Return
    ) async throws(Failure) -> Return {
        try await self.internalContext.timeout(for: duration, body: body)
    }

    /// Waits for the given closure to return `true`.
    ///
    /// The closure receives the current workflow state and is re-evaluated each time the
    /// executor runs (e.g., after a signal handler mutates state). Since the state is passed
    /// as a parameter, there is no need to capture `self`.
    ///
    /// The closure must be side-effect free since it may be invoked frequently during
    /// executor iteration.
    ///
    /// This is very commonly used to wait on a value to be set by a handler. Special care was taken to only resume a single wait
    /// condition when it evaluates to true. Therefore if multiple wait conditions are waiting on the same thing, only one
    /// is resumed at a time, which means the code immediately following that wait condition can change the variable before
    /// other wait conditions are evaluated. This is a useful property for building mutexes/semaphores.
    ///
    /// ## Usage
    ///
    /// ```swift
    /// // Wait for a boolean flag to become true
    /// try await context.condition { $0.approved }
    ///
    /// // Wait for a counter to reach a threshold
    /// try await context.condition { $0.processedItems >= 10 }
    ///
    /// // Wait for an optional value to be set
    /// try await context.condition { $0.result != nil }
    /// ```
    ///
    /// - Parameter condition: A closure that receives the workflow state and returns `true`
    ///   when the condition is satisfied.
    /// - Throws: A `CanceledError` if the waiting was cancelled.
    public func condition(_ condition: @escaping (Workflow) -> Bool) async throws {
        try await self.internalContext.condition { [stateBox] in
            stateBox.withValue { condition($0) }
        }
    }

    /// Waits for the given closure to return `true`.
    ///
    /// Use this overload when the condition does not depend on workflow state properties,
    /// for example when waiting on a value from the context itself.
    ///
    /// ## Usage
    ///
    /// ```swift
    /// // Wait for all handlers to finish
    /// try await context.condition { context.allHandlersFinished }
    /// ```
    ///
    /// - Parameter condition: A closure that returns `true` when the condition is satisfied.
    /// - Throws: A `CanceledError` if the waiting was cancelled.
    public func condition(_ condition: @escaping () -> Bool) async throws {
        try await self.internalContext.condition(condition)
    }

    /// Patches a workflow to support versioning and backward compatibility.
    ///
    /// When called, this returns `true` if code should take the newer path, which means this is either not replaying
    /// or is replaying and has seen this patch before. Results for successive calls to this function for the same ID
    /// and workflow are memoized.
    ///
    /// Use ``deprecatePatch(_:)`` when all workflows are done and will never be queried again.
    /// The old code path can be removed at that time too.
    ///
    /// ## Usage
    ///
    /// ```swift
    /// if context.patch("fix-bug-123") {
    ///     // New code path with the bug fix
    ///     return await newImplementation()
    /// } else {
    ///     // Old code path for backward compatibility
    ///     return await oldImplementation()
    /// }
    /// ```
    ///
    /// - Parameter id: A unique identifier for this patch.
    /// - Returns: A boolean value that indicates whether this should take the newer patch path.
    public func patch(_ id: String) -> Bool {
        self.internalContext.patch(id)
    }

    /// Marks a patch as deprecated.
    ///
    /// This marks a workflow that had ``patch(_:)`` in a previous version of the code as no longer applicable
    /// because all workflows that use the old code path are done and will never be queried again.
    /// Therefore the old code path can be removed as well.
    ///
    /// ## Usage
    ///
    /// ```swift
    /// context.deprecatePatch("fix-bug-123")
    /// // Old code path can now be safely removed
    /// return await newImplementation()
    /// ```
    ///
    /// - Parameter id: The patch identifier to deprecate.
    public func deprecatePatch(_ id: String) {
        self.internalContext.deprecatePatch(id)
    }

    /// Executes an operation with a cancellation shield.
    ///
    /// Use this method to perform operations that should be shielded from workflow cancellation.
    /// For example, you can use this to execute an activity as part of a cleanup operation when your workflow is getting canceled.
    ///
    /// - Parameter operation: The operation that should be executed.
    public func withCancellationShield<Result: Sendable>(_ operation: sending @escaping () async throws -> Result) async throws -> Result {
        try await self.internalContext.withCancellationShield(operation)
    }

    // MARK: - Activity Execution

    /// Executes an activity with the specified type, options, and input.
    ///
    /// ## Usage
    ///
    /// ```swift
    /// // Execute an activity with input
    /// let result = try await context.executeActivity(
    ///     ProcessOrderActivity.self,
    ///     options: .init(startToCloseTimeout: .seconds(30)),
    ///     input: OrderRequest(id: "order-123", items: items)
    /// )
    ///
    /// // Execute with retry policy
    /// let emailResult = try await context.executeActivity(
    ///     SendEmailActivity.self,
    ///     options: .init(
    ///         startToCloseTimeout: .seconds(60),
    ///         retryPolicy: .init(
    ///             maximumAttempts: 3,
    ///             initialInterval: .seconds(1)
    ///         )
    ///     ),
    ///     input: EmailData(to: "user@example.com", subject: "Order Confirmation")
    /// )
    /// ```
    ///
    /// - Parameters:
    ///   - activityType: The activity's type.
    ///   - options: The activity's execution options.
    ///   - input: The activity's input data.
    /// - Returns: The activity's output.
    public func executeActivity<Activity: ActivityDefinition>(
        _ activityType: Activity.Type = Activity.self,
        options: ActivityOptions,
        input: Activity.Input
    ) async throws -> Activity.Output {
        try await executeActivity(
            name: Activity.name,
            options: options,
            input: input,
            outputType: Activity.Output.self
        )
    }

    /// Executes an activity with no input.
    ///
    /// ## Usage
    ///
    /// ```swift
    /// // Execute an activity with no input parameters
    /// let systemInfo = try await context.executeActivity(
    ///     GetSystemInfoActivity.self,
    ///     options: .init(startToCloseTimeout: .seconds(15))
    /// )
    ///
    /// // Health check activity
    /// let isHealthy = try await context.executeActivity(
    ///     HealthCheckActivity.self,
    ///     options: .init(startToCloseTimeout: .seconds(10))
    /// )
    /// ```
    ///
    /// - Parameters:
    ///   - activityType: The activity's type.
    ///   - options: The activity's execution options.
    /// - Returns: The activity's output.
    public func executeActivity<Activity: ActivityDefinition>(
        _ activityType: Activity.Type = Activity.self,
        options: ActivityOptions
    ) async throws -> Activity.Output where Activity.Input == Void {
        try await executeActivity(activityType, options: options, input: ())
    }

    /// Executes an activity with no input or output.
    ///
    /// - Parameters:
    ///   - activityType: The activity's type.
    ///   - options: The activity's execution options.
    public func executeActivity<Activity: ActivityDefinition>(
        _ activityType: Activity.Type = Activity.self,
        options: ActivityOptions
    ) async throws where Activity.Input == Void, Activity.Output == Void {
        try await executeActivity(activityType, options: options, input: ())
    }

    /// Executes an activity with no output.
    ///
    /// - Parameters:
    ///   - activityType: The activity's type.
    ///   - options: The activity's execution options.
    ///   - input: The activity's input data.
    public func executeActivity<Activity: ActivityDefinition>(
        _ activityType: Activity.Type = Activity.self,
        options: ActivityOptions,
        input: Activity.Input
    ) async throws where Activity.Output == Void {
        let _: Void = try await executeActivity(
            name: Activity.name,
            options: options,
            input: input,
            outputType: Activity.Output.self
        )
    }

    /// Executes an activity by name.
    ///
    /// ## Usage
    ///
    /// ```swift
    /// // Execute activity by string name
    /// let result: String = try await context.executeActivity(
    ///     name: "ProcessPayment",
    ///     options: .init(startToCloseTimeout: .seconds(45)),
    ///     input: PaymentRequest(amount: 100.00, currency: "USD"),
    ///     outputType: PaymentResult.self
    /// )
    ///
    /// // Execute with multiple inputs
    /// let summary: OrderSummary = try await context.executeActivity(
    ///     name: "GenerateOrderSummary",
    ///     options: .init(startToCloseTimeout: .seconds(30)),
    ///     input: orderID, customerInfo, items,
    ///     outputType: OrderSummary.self
    /// )
    /// ```
    ///
    /// - Parameters:
    ///   - name: The activity's name.
    ///   - options: The activity's execution options.
    ///   - input: The activity's input values.
    ///   - outputType: The activity's output type.
    /// - Returns: The activity's output.
    public func executeActivity<each Input: Sendable, Output: Sendable>(
        name: String,
        options: ActivityOptions,
        input: repeat each Input,
        outputType: Output.Type = Output.self
    ) async throws -> Output {
        try await self.internalContext.executeActivity(name: name, options: options, input: repeat each input, outputType: outputType)
    }

    // MARK: Local Activity Execution

    /// Executes a local activity with the specified type, options, and input.
    ///
    /// ## Usage
    ///
    /// ```swift
    /// // Execute a local activity with input
    /// let result = try await context.executeLocalActivity(
    ///     ProcessOrderActivity.self,
    ///     options: .init(startToCloseTimeout: .seconds(30)),
    ///     input: OrderRequest(id: "order-123", items: items)
    /// )
    ///
    /// // Execute with retry policy
    /// let emailResult = try await context.executeLocalActivity(
    ///     SendEmailActivity.self,
    ///     options: .init(
    ///         startToCloseTimeout: .seconds(60),
    ///         retryPolicy: .init(
    ///             maximumAttempts: 3,
    ///             initialInterval: .seconds(1)
    ///         )
    ///     ),
    ///     input: EmailData(to: "user@example.com", subject: "Order Confirmation")
    /// )
    /// ```
    ///
    /// - Parameters:
    ///   - activityType: The activity's type.
    ///   - options: The activity's execution options.
    ///   - input: The activity's input data.
    /// - Returns: The activity's output.
    public func executeLocalActivity<Activity: ActivityDefinition>(
        _ activityType: Activity.Type = Activity.self,
        options: LocalActivityOptions,
        input: Activity.Input
    ) async throws -> Activity.Output {
        try await self.executeLocalActivity(
            name: activityType.name,
            options: options,
            input: input,
            outputType: Activity.Output.self
        )
    }

    /// Executes a local activity with no input.
    ///
    /// ## Usage
    ///
    /// ```swift
    /// // Execute a local activity with no input parameters
    /// let systemInfo = try await context.executeLocalActivity(
    ///     GetSystemInfoActivity.self,
    ///     options: .init(startToCloseTimeout: .seconds(15))
    /// )
    ///
    /// // Health check local activity
    /// let isHealthy = try await context.executeLocalActivity(
    ///     HealthCheckActivity.self,
    ///     options: .init(startToCloseTimeout: .seconds(10))
    /// )
    /// ```
    ///
    /// - Parameters:
    ///   - activityType: The activity's type.
    ///   - options: The activity's execution options.
    /// - Returns: The activity's output.
    public func executeLocalActivity<Activity: ActivityDefinition>(
        _ activityType: Activity.Type = Activity.self,
        options: LocalActivityOptions
    ) async throws -> Activity.Output where Activity.Input == Void {
        try await self.executeLocalActivity(
            activityType,
            options: options,
            input: ()
        )
    }

    /// Executes a local activity with no input or output.
    ///
    /// - Parameters:
    ///   - activityType: The activity's type.
    ///   - options: The local activity's execution options.
    public func executeLocalActivity<Activity: ActivityDefinition>(
        _ activityType: Activity.Type = Activity.self,
        options: LocalActivityOptions
    ) async throws where Activity.Input == Void, Activity.Output == Void {
        try await self.executeLocalActivity(
            activityType,
            options: options,
            input: ()
        )
    }

    /// Executes a local activity with no output.
    ///
    /// - Parameters:
    ///   - activityType: The activity's type.
    ///   - options: The local activity's execution options.
    ///   - input: The activity's input data.
    public func executeLocalActivity<Activity: ActivityDefinition>(
        _ activityType: Activity.Type = Activity.self,
        options: LocalActivityOptions,
        input: Activity.Input
    ) async throws where Activity.Output == Void {
        try await self.executeLocalActivity(
            name: activityType.name,
            options: options,
            input: input,
            outputType: Activity.Output.self
        )
    }

    /// Executes a local activity by name.
    ///
    /// ## Usage
    ///
    /// ```swift
    /// // Execute local activity by string name
    /// let result: String = try await context.executeLocalActivity(
    ///     name: "ProcessPayment",
    ///     options: .init(startToCloseTimeout: .seconds(45)),
    ///     input: PaymentRequest(amount: 100.00, currency: "USD"),
    ///     outputType: PaymentResult.self
    /// )
    ///
    /// // Execute with multiple inputs
    /// let summary: OrderSummary = try await context.executeLocalActivity(
    ///     name: "GenerateOrderSummary",
    ///     options: .init(startToCloseTimeout: .seconds(30)),
    ///     input: orderID, customerInfo, items,
    ///     outputType: OrderSummary.self
    /// )
    /// ```
    ///
    /// - Parameters:
    ///   - name: The local activity's name.
    ///   - options: The local activity's execution options.
    ///   - input: The local activity's input values.
    ///   - outputType: The local activity's output type.
    /// - Returns: The local activity's output.
    public func executeLocalActivity<each Input: Sendable, Output: Sendable>(
        name: String,
        options: LocalActivityOptions,
        input: repeat each Input,
        outputType: Output.Type = Output.self
    ) async throws -> Output {
        try await self.internalContext.executeLocalActivity(
            name: name,
            options: options,
            input: repeat each input,
            outputType: outputType
        )
    }

    // MARK: - External Workflow

    /// Returns a typed handle to an external workflow for type-safe signaling and cancellation.
    ///
    /// The external workflow handle allows a workflow to interact with any other workflow by ID,
    /// regardless of whether it is a child workflow. This typed variant provides compile-time
    /// safety for signal operations using ``WorkflowSignalDefinition``.
    ///
    /// ## Usage
    ///
    /// ```swift
    /// let handle = context.getExternalWorkflowHandle(
    ///     ExternalTargetWorkflow.self,
    ///     id: "other-workflow-id"
    /// )
    ///
    /// // Signal the external workflow with type safety
    /// try await handle.signal(signalType: ExternalTargetWorkflow.MySignal.self, input: signalData)
    ///
    /// // Cancel the external workflow
    /// try await handle.cancel()
    /// ```
    ///
    /// - Parameters:
    ///   - type: The workflow type of the external workflow.
    ///   - id: The workflow ID of the external workflow.
    ///   - runId: The optional run ID of the external workflow. If `nil`, targets the latest run.
    /// - Returns: A typed handle to the external workflow.
    public func getExternalWorkflowHandle<ExternalW: WorkflowDefinition>(
        _ type: ExternalW.Type,
        id: String,
        runId: String? = nil
    ) -> ExternalWorkflowHandle<ExternalW> {
        ExternalWorkflowHandle(
            untypedHandle: self.internalContext.getExternalWorkflowHandle(id: id, runId: runId)
        )
    }

    /// Returns an untyped handle to an external workflow for signaling and cancellation.
    ///
    /// The external workflow handle allows a workflow to interact with any other workflow by ID,
    /// regardless of whether it is a child workflow. This is useful for cross-workflow communication
    /// and coordination when the workflow type is not known at compile time.
    ///
    /// ## Usage
    ///
    /// ```swift
    /// let handle = context.getExternalWorkflowHandle(id: "other-workflow-id")
    ///
    /// // Signal the external workflow
    /// try await handle.signal(signalName: "mySignal", input: signalData)
    ///
    /// // Cancel the external workflow
    /// try await handle.cancel()
    /// ```
    ///
    /// - Parameters:
    ///   - id: The workflow ID of the external workflow.
    ///   - runId: The optional run ID of the external workflow. If `nil`, targets the latest run.
    /// - Returns: An untyped handle to the external workflow.
    public func getExternalWorkflowHandle(
        id: String,
        runId: String? = nil
    ) -> UntypedExternalWorkflowHandle {
        self.internalContext.getExternalWorkflowHandle(id: id, runId: runId)
    }

    // MARK: - Child Workflow

    /// Starts a child workflow and returns a handle to track its execution.
    ///
    /// ## Usage
    ///
    /// ```swift
    /// // Start a child workflow and get a handle
    /// let childHandle = try await context.startChildWorkflow(
    ///     ProcessOrderWorkflow.self,
    ///     input: OrderData(id: "order-456", customerID: "customer-789")
    /// )
    ///
    /// // Start with custom task queue
    /// let reportHandle = try await context.startChildWorkflow(
    ///     GenerateReportWorkflow.self,
    ///     options: .init(
    ///         taskQueue: "reports-task-queue"
    ///     ),
    ///     input: ReportRequest(startDate: startDate, endDate: endDate)
    /// )
    ///
    /// // Later, get the result
    /// let result = try await childHandle.result()
    /// ```
    ///
    /// - Parameters:
    ///   - workflowType: The workflow's type.
    ///   - options: The child workflow options.
    ///   - input: The input to the workflow.
    /// - Returns: A handle to the child workflow.
    public func startChildWorkflow<ChildWorkflow: WorkflowDefinition>(
        _ workflowType: ChildWorkflow.Type = ChildWorkflow.self,
        options: ChildWorkflowOptions = .init(),
        input: ChildWorkflow.Input
    ) async throws -> ChildWorkflowHandle<ChildWorkflow> {
        try await self.internalContext.startChildWorkflow(workflowType: workflowType, options: options, input: input)
    }

    /// Starts a child workflow by name.
    ///
    /// - Parameters:
    ///   - name: The type name of the workflow.
    ///   - options: The child workflow options.
    ///   - inputs: The inputs to the child workflow.
    /// - Returns: A handle to the child workflow.
    public func startChildWorkflow<each Input: Sendable>(
        name: String,
        options: ChildWorkflowOptions = .init(),
        inputs: repeat each Input
    ) async throws -> UntypedChildWorkflowHandle {
        try await self.internalContext.startChildWorkflow(name: name, options: options, inputs: repeat each inputs)
    }

    /// Starts a child workflow and awaits the result.
    ///
    /// ## Usage
    ///
    /// ```swift
    /// // Execute child workflow and wait for result
    /// let processedOrder = try await context.executeChildWorkflow(
    ///     ProcessOrderWorkflow.self,
    ///     input: OrderData(id: orderID, items: items, customerID: customerID)
    /// )
    ///
    /// // Execute multiple child workflows in parallel
    /// async let emailResult = context.executeChildWorkflow(
    ///     SendEmailWorkflow.self,
    ///     input: EmailNotification(to: customer.email, template: "order-confirmation")
    /// )
    /// async let smsResult = context.executeChildWorkflow(
    ///     SendSmsWorkflow.self,
    ///     input: SmsNotification(to: customer.phone, message: "Order confirmed")
    /// )
    ///
    /// let (emailSent, smsSent) = try await (emailResult, smsResult)
    /// ```
    ///
    /// - Parameters:
    ///   - workflowType: The workflow's type.
    ///   - options: The child workflow options.
    ///   - input: The input to the workflow.
    /// - Returns: The child workflow's output.
    public func executeChildWorkflow<ChildWorkflow: WorkflowDefinition>(
        _ workflowType: ChildWorkflow.Type = ChildWorkflow.self,
        options: ChildWorkflowOptions = .init(),
        input: ChildWorkflow.Input
    ) async throws -> ChildWorkflow.Output {
        try await startChildWorkflow(workflowType, options: options, input: input).result()
    }

    /// Starts a child workflow by name and awaits the result.
    ///
    /// - Parameters:
    ///   - name: The type name of the workflow.
    ///   - options: The child workflow options.
    ///   - inputs: The inputs to the child workflow.
    ///   - resultType: The type of the workflow's result.
    /// - Returns: The child workflow's output.
    public func executeChildWorkflow<each Input: Sendable, Result: Sendable>(
        name: String,
        options: ChildWorkflowOptions = .init(),
        inputs: repeat each Input,
        resultType: Result.Type = Result.self
    ) async throws -> Result {
        try await startChildWorkflow(name: name, options: options, inputs: repeat each inputs).result(resultType: resultType)
    }

    // MARK: - Memo

    /// Gets the value for a memo key.
    ///
    /// ## Usage
    ///
    /// ```swift
    /// // Get a string memo value
    /// let customerType: String? = try await context.getMemoValue(for: "customer_type")
    ///
    /// // Get a custom struct memo value
    /// let config: WorkflowConfig? = try await context.getMemoValue(for: "workflow_config")
    ///
    /// // Handle optional memo values
    /// let priority: Int? = try await context.getMemoValue(for: "priority")
    /// let effectivePriority = priority ?? 1 // Default if not set
    ///
    /// // Check if memo exists and handle accordingly
    /// if let experimentGroup: String = try await context.getMemoValue(for: "experiment_group") {
    ///     // Use experiment-specific logic
    ///     processExperimentalFeature(group: experimentGroup)
    /// } else {
    ///     // Use default behavior
    ///     processStandardFeature()
    /// }
    /// ```
    ///
    /// - Parameter key: The memo's key.
    /// - Parameter valueType: The memo's value's type.
    /// - Returns: The value if present, otherwise `nil`.
    public func getMemoValue<Value>(
        for key: String,
        as valueType: Value.Type = Value.self
    ) async throws -> Value? {
        try await self.internalContext.getMemoValue(for: key)
    }

    /// Issues updates to the workflow memo.
    ///
    /// ## Usage
    ///
    /// ```swift
    /// // Update memo with various data types
    /// try await context.upsertMemo([
    ///     "customer_id": "customer-123",
    ///     "order_total": 150.75,
    ///     "priority": 2,
    ///     "is_premium": true
    /// ])
    ///
    /// // Update specific memo fields
    /// try await context.upsertMemo([
    ///     "status": "processing",
    ///     "last_updated": Date().timeIntervalSince1970
    /// ])
    ///
    /// // Remove memo fields by setting to nil
    /// try await context.upsertMemo([
    ///     "temporary_flag": nil,  // Remove this field
    ///     "debug_info": nil       // Remove this field too
    /// ])
    ///
    /// // Store complex objects
    /// let workflowMetadata = WorkflowMetadata(
    ///     version: "2.1",
    ///     feature_flags: ["new_checkout": true]
    /// )
    /// try await context.upsertMemo([
    ///     "metadata": workflowMetadata
    /// ])
    /// ```
    ///
    /// - Parameter memo: Updates to apply. Value can be `nil` to effectively remove the
    ///   memo value.
    public func upsertMemo(_ memo: [String: (any Sendable)?]) async throws {
        try await self.internalContext.upsertMemo(memo)
    }

    // MARK: - Continue As New

    /// Creates a continue-as-new error to restart the workflow as the same type.
    ///
    /// ## Usage
    ///
    /// ```swift
    /// // Continue as new with updated input
    /// if context.continueAsNewSuggested {
    ///     let continueError = try await context.makeContinueAsNewError(
    ///         options: .init(),
    ///         input: WorkflowInput(
    ///             processedItems: currentState.processedItems,
    ///             nextBatchStartID: currentState.lastProcessedID + 1
    ///         )
    ///     )
    ///     throw continueError
    /// }
    ///
    /// // Continue with same input but different task queue
    /// if shouldMigrateToNewTaskQueue {
    ///     let continueError = try await context.makeContinueAsNewError(
    ///         options: .init(taskQueue: "new-task-queue-v2"),
    ///         input: currentInput
    ///     )
    ///     throw continueError
    /// }
    ///
    /// // Continue with multiple parameters
    /// let continueError = try await context.makeContinueAsNewError(
    ///     options: .init(),
    ///     input: newUserID, updatedConfig, processedCount
    /// )
    /// throw continueError
    /// ```
    ///
    /// - Parameters:
    ///   - options: The continue-as-new options.
    ///   - input: The input values for the new workflow execution.
    /// - Returns: A continue-as-new error.
    /// - Throws: When the input, headers or memo fails to convert.
    public func makeContinueAsNewError<each Input: Sendable>(
        options: ContinueAsNewOptions,
        input: repeat each Input
    ) async throws -> ContinueAsNewError {
        try await self.internalContext.makeContinueAsNewError(
            workflowName: self.info.workflowName,
            options: options,
            input: repeat each input
        )
    }

    /// Creates a continue-as-new error to restart as a different workflow type.
    ///
    /// This overload allows continuing execution as a different workflow type.
    ///
    /// ## Usage
    ///
    /// ```swift
    /// // Continue as a different workflow type
    /// throw try await context.makeContinueAsNewError(
    ///     workflowType: ProcessingWorkflowV2.self,
    ///     options: .init(),
    ///     input: migratedInput
    /// )
    /// ```
    ///
    /// - Parameters:
    ///   - workflowType: The workflow type to continue as.
    ///   - options: The continue-as-new options.
    ///   - input: The input values for the new workflow execution.
    /// - Returns: A continue-as-new error.
    /// - Throws: When the input, headers or memo fails to convert.
    public func makeContinueAsNewError<OtherW: WorkflowDefinition, each Input: Sendable>(
        workflowType: OtherW.Type,
        options: ContinueAsNewOptions = .init(),
        input: repeat each Input
    ) async throws -> ContinueAsNewError {
        try await self.internalContext.makeContinueAsNewError(
            workflowName: OtherW.name,
            options: options,
            input: repeat each input
        )
    }

    /// Creates a continue-as-new error to restart as a different workflow by name.
    ///
    /// This overload allows continuing execution as a different workflow identified by its
    /// string name. This is useful when the workflow type is not available at compile time.
    ///
    /// ## Usage
    ///
    /// ```swift
    /// // Continue as a different workflow by name
    /// throw try await context.makeContinueAsNewError(
    ///     workflowName: "ProcessingWorkflowV2",
    ///     options: .init(),
    ///     input: migratedInput
    /// )
    /// ```
    ///
    /// - Parameters:
    ///   - workflowName: The name of the workflow to continue as.
    ///   - options: The continue-as-new options.
    ///   - input: The input values for the new workflow execution.
    /// - Returns: A continue-as-new error.
    /// - Throws: When the input, headers or memo fails to convert.
    public func makeContinueAsNewError<each Input: Sendable>(
        workflowName: String,
        options: ContinueAsNewOptions = .init(),
        input: repeat each Input
    ) async throws -> ContinueAsNewError {
        try await self.internalContext.makeContinueAsNewError(
            workflowName: workflowName,
            options: options,
            input: repeat each input
        )
    }
}
