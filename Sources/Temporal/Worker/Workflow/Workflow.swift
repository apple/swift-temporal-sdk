//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Temporal SDK open source project
//
// Copyright (c) 2025 Apple Inc. and the Swift Temporal SDK project authors
// Licensed under MIT License
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Swift Cassandra Client project authors
//
// SPDX-License-Identifier: MIT
//
//===----------------------------------------------------------------------===//

import Logging

import struct Foundation.Date

/// Static workflow API that provides access to Temporal workflow operations.
///
/// The Workflow struct provides static methods for all workflow operations including activity execution,
/// child workflow management, timers, conditions, and workflow state management. It serves as the primary
/// interface through which workflows interact with the Temporal system.
///
/// ## Deterministic execution
///
/// All operations performed through the Workflow API are deterministic and replay-safe.
/// The API ensures that workflow executions are consistent across retries and replay scenarios.
///
/// ## Usage
///
/// The Workflow API uses task-local storage to access the current workflow context:
///
/// ```swift
/// func run(input: MyInput) async throws -> MyOutput {
///     // Execute an activity
///     let result = try await Workflow.executeActivity(
///         MyActivity.self,
///         options: .init(startToCloseTimeout: .seconds(30)),
///         input: "hello"
///     )
///
///     // Sleep for a duration
///     try await Workflow.sleep(for: .seconds(5))
///
///     // Wait for a condition
///     try await Workflow.condition { someState == expectedValue }
///
///     return result
/// }
/// ```
///
/// - Important: This type is only valid for use within the scope of a workflow execution.
public struct Workflow: Sendable {
    @TaskLocal package static var context: WorkflowContext?

    private static var _context: WorkflowContext {
        guard let context = context else {
            fatalError("Workflow context is not available. This API can only be used within a workflow execution.")
        }
        return context
    }

    /// Information about the current workflow execution.
    ///
    /// Provides access to workflow metadata including identifiers, timing information,
    /// configuration, and parent workflow details.
    public static var info: WorkflowInfo {
        self._context.info
    }

    /// The data converter used for payload serialization and deserialization.
    ///
    /// This converter handles the transformation between Swift types and Temporal's
    /// internal payload format.
    public static var payloadConverter: any PayloadConverter {
        self._context.payloadConverter
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
    /// var rng = Workflow.randomNumberGenerator
    /// let randomValue = Int.random(in: 1...100, using: &rng)
    /// ```
    public static var randomNumberGenerator: RandomNumberGenerator {
        self._context.randomNumberGenerator
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
    /// func run(input: Void) async throws {
    ///     // Perform workflow logic...
    ///
    ///     // Wait for all handlers to finish before returning
    ///     try await Workflow.condition { Workflow.allHandlersFinished }
    /// }
    /// ```
    ///
    /// - Returns: `true` if all handlers have finished, `false` otherwise.
    public static var allHandlersFinished: Bool {
        self._context.allHandlersFinished
    }

    /// The current date of the workflow.
    ///
    /// This value is deterministic and safe for replays.
    /// Do not use any other sources of system time in workflows.
    public static var now: Date {
        self._context.now
    }

    /// Indicates whether the workflow is currently in replay mode.
    package static var isReplaying: Bool {
        self._context.isReplaying
    }

    /// The current search attributes for the workflow.
    ///
    /// Search attributes are key-value pairs that can be used to index and query
    /// workflow executions. They are searchable through Temporal's visibility APIs.
    ///
    /// - Returns: A collection of the current search attributes.
    public static var searchAttributes: SearchAttributeCollection {
        self._context.searchAttributes
    }

    /// User specified details for this workflow that may appear in UI/CLI.
    ///
    /// Unlike static details set at start, this value can be updated throughout the life of the workflow.
    /// This can be in Temporal markdown format and can span multiple lines.
    ///
    /// - Important: This is currently experimental.
    public static var currentDetails: String? {
        get { self._context.currentDetails }
        set {
            guard let context = context else {
                fatalError("Workflow context is not available. This API can only be used within a workflow execution.")
            }
            // Use the internal method since the context struct is immutable
            context.updateCurrentDetails(newValue)
        }
    }

    /// A boolean value that indicates whether continue as new was suggested.
    public static var continueAsNewSuggested: Bool {
        self._context.continueAsNewSuggested
    }

    /// Current number of events in the history.
    public static var currentHistoryLength: Int {
        self._context.currentHistoryLength
    }

    /// Current size of the history in bytes.
    public static var currentHistorySize: Int {
        self._context.currentHistorySize
    }

    /// The logger used for the workflow execution.
    public static var logger: Logger {
        self._context.logger
    }

    /// Ensures that state modifications of the workflow are safe.
    package static func ensureWorkflowStateModificationIsSafe() {
        self._context.ensureWorkflowStateModificationIsSafe()
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
    /// Workflow.upsertSearchAttributes(attributes)
    /// ```
    ///
    /// - Parameter searchAttributes: The search attributes to update or insert.
    ///   Specify `nil` for a specific attribute to unset it.
    public static func upsertSearchAttributes(_ searchAttributes: SearchAttributeCollection) {
        self._context.upsertSearchAttributes(searchAttributes)
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
    /// Workflow.upsertSearchAttributes { attributes in
    ///     attributes[.customStringField("status")] = "completed"
    ///     attributes[.customIntField("score")] = 100
    ///     attributes[.customStringField("old_field")] = nil // Unset
    /// }
    /// ```
    public static func upsertSearchAttributes(builder: (inout SearchAttributeCollection) -> Void) {
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
    /// try await Workflow.sleep(for: .seconds(5))
    ///
    /// // Sleep with a summary for debugging
    /// try await Workflow.sleep(for: .minutes(1), summary: "waiting for external system")
    /// ```
    ///
    /// - Parameter duration: The duration to sleep for.
    /// - Parameter summary: A simple string identifying this timer.
    public static func sleep(for duration: Duration, summary: String? = nil) async throws {
        try await self._context.sleep(for: duration, summary: summary)
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
    /// let result = try await Workflow.timeout(for: .seconds(30)) {
    ///     return try await performLongRunningOperation()
    /// }
    ///
    /// // Handle timeout by catching cancellation in the body
    /// let result = try await Workflow.timeout(for: .minutes(2)) {
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
    public static func timeout<Return: Sendable, Failure: Error>(
        for duration: Duration,
        body: @Sendable @escaping () async throws(Failure) -> Return
    ) async throws(Failure) -> Return {
        try await self._context.timeout(for: duration, body: body)
    }

    /// Waits for the given closure to return `true`.
    ///
    /// The closure must be side-effect free since it may be invoked frequently during
    /// executor iteration.
    ///
    /// This is very commonly used to wait on a value to be set by a handler. Special care was taken to only resume up a single wait
    /// condition when it evaluates to true. Therefore if multiple wait conditions are waiting on the same thing, only one
    /// is resumed at a time, which means the code immediately following that wait condition can change the variable before
    /// other wait conditions are evaluated. This is a useful property for building mutexes/semaphores.
    ///
    /// ## Usage
    ///
    /// ```swift
    /// // Wait for a boolean flag to become true
    /// var isReady = false
    /// try await Workflow.condition { isReady }
    ///
    /// // Wait for a counter to reach a threshold
    /// var processedItems = 0
    /// try await Workflow.condition { processedItems >= 10 }
    ///
    /// // Wait for an optional value to be set
    /// var result: String?
    /// try await Workflow.condition { result != nil }
    /// ```
    ///
    /// - Parameter condition: The closure to run many times to test if the condition evaluates to `true`.
    /// - Throws: A `CanceledError` if the waiting was cancelled.
    public static func condition(_ condition: @escaping () -> Bool) async throws {
        try await self._context.condition(condition)
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
    /// if Workflow.patch("fix-bug-123") {
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
    public static func patch(_ id: String) -> Bool {
        self._context.patch(id)
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
    /// Workflow.deprecatePatch("fix-bug-123")
    /// // Old code path can now be safely removed
    /// return await newImplementation()
    /// ```
    ///
    /// - Parameter id: The patch identifier to deprecate.
    public static func deprecatePatch(_ id: String) {
        self._context.deprecatePatch(id)
    }

    /// Execute an operation with a cancellation shield.
    ///
    /// Use this method to perform operations that should be shielded from Workflow cancellation.
    /// For example, you can use this to execute an activity as part of a cleanup operation when your Workflow is getting cancelled.
    ///
    /// - Parameter operation: The operation that should be executed.
    public static func withCancellationShield<Result: Sendable>(_ operation: sending @escaping () async throws -> Result) async throws -> Result {
        try await self._context.withCancellationShield(operation)
    }

    // MARK: - Activity Execution

    /// Executes an activity with the specified type, options, and input.
    ///
    /// ## Usage
    ///
    /// ```swift
    /// // Execute an activity with input
    /// let result = try await Workflow.executeActivity(
    ///     ProcessOrderActivity.self,
    ///     options: .init(startToCloseTimeout: .seconds(30)),
    ///     input: OrderRequest(id: "order-123", items: items)
    /// )
    ///
    /// // Execute with retry policy
    /// let emailResult = try await Workflow.executeActivity(
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
    public static func executeActivity<Activity: ActivityDefinition>(
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
    /// let systemInfo = try await Workflow.executeActivity(
    ///     GetSystemInfoActivity.self,
    ///     options: .init(startToCloseTimeout: .seconds(15))
    /// )
    ///
    /// // Health check activity
    /// let isHealthy = try await Workflow.executeActivity(
    ///     HealthCheckActivity.self,
    ///     options: .init(startToCloseTimeout: .seconds(10))
    /// )
    /// ```
    ///
    /// - Parameters:
    ///   - activityType: The activity's type.
    ///   - options: The activity's execution options.
    /// - Returns: The activity's output.
    public static func executeActivity<Activity: ActivityDefinition>(
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
    public static func executeActivity<Activity: ActivityDefinition>(
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
    public static func executeActivity<Activity: ActivityDefinition>(
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
    /// let result: String = try await Workflow.executeActivity(
    ///     name: "ProcessPayment",
    ///     options: .init(startToCloseTimeout: .seconds(45)),
    ///     input: PaymentRequest(amount: 100.00, currency: "USD"),
    ///     outputType: PaymentResult.self
    /// )
    ///
    /// // Execute with multiple inputs
    /// let summary: OrderSummary = try await Workflow.executeActivity(
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
    public static func executeActivity<each Input: Sendable, Output: Sendable>(
        name: String,
        options: ActivityOptions,
        input: repeat each Input,
        outputType: Output.Type = Output.self
    ) async throws -> Output {
        try await self._context.executeActivity(name: name, options: options, input: repeat each input, outputType: outputType)
    }

    // MARK: Local Activity Execution

    /// Executes a local activity with the specified type, options, and input.
    ///
    /// ## Usage
    ///
    /// ```swift
    /// // Execute a local activity with input
    /// let result = try await Workflow.executeLocalActivity(
    ///     ProcessOrderActivity.self,
    ///     options: .init(startToCloseTimeout: .seconds(30)),
    ///     input: OrderRequest(id: "order-123", items: items)
    /// )
    ///
    /// // Execute with retry policy
    /// let emailResult = try await Workflow.executeLocalActivity(
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
    public static func executeLocalActivity<Activity: ActivityDefinition>(
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
    /// let systemInfo = try await Workflow.executeLocalActivity(
    ///     GetSystemInfoActivity.self,
    ///     options: .init(startToCloseTimeout: .seconds(15))
    /// )
    ///
    /// // Health check local activity
    /// let isHealthy = try await Workflow.executeLocalActivity(
    ///     HealthCheckActivity.self,
    ///     options: .init(startToCloseTimeout: .seconds(10))
    /// )
    /// ```
    ///
    /// - Parameters:
    ///   - activityType: The activity's type.
    ///   - options: The activity's execution options.
    /// - Returns: The activity's output.
    public static func executeLocalActivity<Activity: ActivityDefinition>(
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
    public static func executeLocalActivity<Activity: ActivityDefinition>(
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
    public static func executeLocalActivity<Activity: ActivityDefinition>(
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
    /// let result: String = try await Workflow.executeLocalActivity(
    ///     name: "ProcessPayment",
    ///     options: .init(startToCloseTimeout: .seconds(45)),
    ///     input: PaymentRequest(amount: 100.00, currency: "USD"),
    ///     outputType: PaymentResult.self
    /// )
    ///
    /// // Execute with multiple inputs
    /// let summary: OrderSummary = try await Workflow.executeLocalActivity(
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
    public static func executeLocalActivity<each Input: Sendable, Output: Sendable>(
        name: String,
        options: LocalActivityOptions,
        input: repeat each Input,
        outputType: Output.Type = Output.self
    ) async throws -> Output {
        try await self._context.executeLocalActivity(
            name: name,
            options: options,
            input: repeat each input,
            outputType: outputType
        )
    }

    // MARK: - Child Workflow

    /// Starts a child workflow.
    ///
    /// ## Usage
    ///
    /// ```swift
    /// // Start a child workflow and get a handle
    /// let childHandle = try await Workflow.startChildWorkflow(
    ///     ProcessOrderWorkflow.self,
    ///     input: OrderData(id: "order-456", customerID: "customer-789")
    /// )
    ///
    /// // Start with custom task queue
    /// let reportHandle = try await Workflow.startChildWorkflow(
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
    public static func startChildWorkflow<ChildWorkflow: WorkflowDefinition>(
        _ workflowType: ChildWorkflow.Type = ChildWorkflow.self,
        options: ChildWorkflowOptions = .init(),
        input: ChildWorkflow.Input
    ) async throws -> ChildWorkflowHandle<ChildWorkflow> {
        try await self._context.startChildWorkflow(workflowType: workflowType, options: options, input: input)
    }

    /// Starts a child workflow by name.
    ///
    /// - Parameters:
    ///   - name: The type name of the workflow.
    ///   - options: The child workflow options.
    ///   - inputs: The inputs to the child workflow.
    /// - Returns: A handle to the child workflow.
    public static func startChildWorkflow<each Input: Sendable>(
        name: String,
        options: ChildWorkflowOptions = .init(),
        inputs: repeat each Input
    ) async throws -> UntypedChildWorkflowHandle {
        try await self._context.startChildWorkflow(name: name, options: options, inputs: repeat each inputs)
    }

    /// Starts a child workflow and awaits the result.
    ///
    /// ## Usage
    ///
    /// ```swift
    /// // Execute child workflow and wait for result
    /// let processedOrder = try await Workflow.executeChildWorkflow(
    ///     ProcessOrderWorkflow.self,
    ///     input: OrderData(id: orderID, items: items, customerID: customerID)
    /// )
    ///
    /// // Execute multiple child workflows in parallel
    /// async let emailResult = Workflow.executeChildWorkflow(
    ///     SendEmailWorkflow.self,
    ///     input: EmailNotification(to: customer.email, template: "order-confirmation")
    /// )
    /// async let smsResult = Workflow.executeChildWorkflow(
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
    public static func executeChildWorkflow<ChildWorkflow: WorkflowDefinition>(
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
    public static func executeChildWorkflow<each Input: Sendable, Result: Sendable>(
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
    /// let customerType: String? = try await Workflow.getMemoValue(for: "customer_type")
    ///
    /// // Get a custom struct memo value
    /// let config: WorkflowConfig? = try await Workflow.getMemoValue(for: "workflow_config")
    ///
    /// // Handle optional memo values
    /// let priority: Int? = try await Workflow.getMemoValue(for: "priority")
    /// let effectivePriority = priority ?? 1 // Default if not set
    ///
    /// // Check if memo exists and handle accordingly
    /// if let experimentGroup: String = try await Workflow.getMemoValue(for: "experiment_group") {
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
    public static func getMemoValue<Value>(
        for key: String,
        as valueType: Value.Type = Value.self
    ) async throws -> Value? {
        try await self._context.getMemoValue(for: key)
    }

    /// Issues updates to the workflow memo.
    ///
    /// ## Usage
    ///
    /// ```swift
    /// // Update memo with various data types
    /// try await Workflow.upsertMemo([
    ///     "customer_id": "customer-123",
    ///     "order_total": 150.75,
    ///     "priority": 2,
    ///     "is_premium": true
    /// ])
    ///
    /// // Update specific memo fields
    /// try await Workflow.upsertMemo([
    ///     "status": "processing",
    ///     "last_updated": Date().timeIntervalSince1970
    /// ])
    ///
    /// // Remove memo fields by setting to nil
    /// try await Workflow.upsertMemo([
    ///     "temporary_flag": nil,  // Remove this field
    ///     "debug_info": nil       // Remove this field too
    /// ])
    ///
    /// // Store complex objects
    /// let workflowMetadata = WorkflowMetadata(
    ///     version: "2.1",
    ///     feature_flags: ["new_checkout": true]
    /// )
    /// try await Workflow.upsertMemo([
    ///     "metadata": workflowMetadata
    /// ])
    /// ```
    ///
    /// - Parameter memo: Updates to apply. Value can be `nil` to effectively remove the
    ///   memo value.
    public static func upsertMemo(_ memo: [String: (any Sendable)?]) async throws {
        try await self._context.upsertMemo(memo)
    }

    // MARK: - Continue As New

    /// Creates a continue-as-new error to restart the workflow.
    ///
    /// ## Usage
    ///
    /// ```swift
    /// // Continue as new with updated input
    /// if Workflow.continueAsNewSuggested {
    ///     let continueError = try await Workflow.makeContinueAsNewError(
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
    ///     let continueError = try await Workflow.makeContinueAsNewError(
    ///         options: .init(taskQueue: "new-task-queue-v2"),
    ///         input: currentInput
    ///     )
    ///     throw continueError
    /// }
    ///
    /// // Continue with multiple parameters
    /// let continueError = try await Workflow.makeContinueAsNewError(
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
    public static func makeContinueAsNewError<each Input: Sendable>(
        options: ContinueAsNewOptions,
        input: repeat each Input
    ) async throws -> ContinueAsNewError {
        try await self._context.makeContinueAsNewError(options: options, input: repeat each input)
    }
}
