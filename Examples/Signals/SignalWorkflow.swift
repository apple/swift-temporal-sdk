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

import Temporal

/// Demonstrates signals, queries, and updates in a realistic order processing workflow.
///
/// This workflow shows:.
/// - Using signals to control workflow execution (pause/resume/cancel)
/// - Using queries to inspect workflow state without mutation
/// - Using updates to modify workflow state synchronously with validation
/// - Waiting for conditions with context.condition
@Workflow
struct SignalWorkflow {
    // MARK: - Input/Output Types

    struct OrderInput: Codable {
        let orderId: String
        let customerId: String
        let items: [String]
    }

    struct OrderOutput: Codable {
        let orderId: String
        let status: String
        let processedId: String?
        let trackingNumber: String?
        let priority: String
    }

    // MARK: - Signal Input Types

    struct SetPriorityInput: Codable {
        let priority: String
    }

    // MARK: - Query Output Types

    struct OrderStatus: Codable {
        let orderId: String
        let currentState: String
        let isPaused: Bool
        let isCancelled: Bool
        let priority: String
        let completedSteps: [String]
    }

    // MARK: - Workflow State

    var currentState: String = "pending"
    var isPaused: Bool = false
    var isCancelled: Bool = false
    var priority: String = "standard"
    var completedSteps: [String] = []
    var orderId: String = ""

    init(input: OrderInput) {
        self.orderId = input.orderId
    }

    // MARK: - Workflow Implementation

    mutating func run(context: WorkflowContext<Self>, input: OrderInput) async throws -> OrderOutput {
        self.currentState = "processing"

        // Step 1: Process the order
        self.completedSteps.append("started")

        // Wait if paused
        try await context.condition { !$0.isPaused || $0.isCancelled }
        if isCancelled {
            return cancelledOutput()
        }

        self.currentState = "processing_order"
        let processedId = try await context.executeActivity(
            SignalActivities.Activities.ProcessOrder.self,
            options: .init(startToCloseTimeout: .seconds(30)),
            input: SignalActivities.ProcessOrderInput(
                orderId: input.orderId,
                items: input.items
            )
        )
        self.completedSteps.append("order_processed")

        // Wait if paused
        try await context.condition { !$0.isPaused || $0.isCancelled }
        if isCancelled {
            return cancelledOutput()
        }

        // Step 2: Ship the order
        self.currentState = "shipping"
        let trackingNumber = try await context.executeActivity(
            SignalActivities.Activities.ShipOrder.self,
            options: .init(startToCloseTimeout: .seconds(30)),
            input: SignalActivities.ShipOrderInput(
                orderId: input.orderId,
                priority: priority
            )
        )
        self.completedSteps.append("order_shipped")

        // Wait if paused
        try await context.condition { !$0.isPaused || $0.isCancelled }
        if isCancelled {
            return cancelledOutput()
        }

        // Step 3: Notify customer
        self.currentState = "notifying"
        try await context.executeActivity(
            SignalActivities.Activities.NotifyCustomer.self,
            options: .init(startToCloseTimeout: .seconds(30)),
            input: "Your order \(input.orderId) has shipped! Tracking: \(trackingNumber)"
        )
        self.completedSteps.append("customer_notified")

        self.currentState = "completed"
        return OrderOutput(
            orderId: input.orderId,
            status: "completed",
            processedId: processedId,
            trackingNumber: trackingNumber,
            priority: priority
        )
    }

    // MARK: - Signal Handlers

    /// Pauses the workflow execution.
    @WorkflowSignal
    mutating func pause(input: Void) {
        isPaused = true
    }

    /// Resumes the workflow execution.
    @WorkflowSignal
    mutating func resume(input: Void) {
        isPaused = false
    }

    /// Cancels the workflow.
    @WorkflowSignal
    mutating func cancel(input: Void) {
        isCancelled = true
        isPaused = false  // Unpause if paused to allow cancellation to proceed
    }

    // MARK: - Query Handlers

    /// Returns the current status of the order.
    @WorkflowQuery
    func getStatus(input: Void) throws -> OrderStatus {
        return OrderStatus(
            orderId: orderId,
            currentState: currentState,
            isPaused: isPaused,
            isCancelled: isCancelled,
            priority: priority,
            completedSteps: completedSteps
        )
    }

    // MARK: - Update Handlers

    /// Updates the priority of the order with validation.
    @WorkflowUpdate
    mutating func setPriority(input: SetPriorityInput) throws -> String {
        // Validate priority value
        let validPriorities = ["standard", "expedited", "overnight"]
        guard validPriorities.contains(input.priority) else {
            throw ApplicationError(
                message: "Invalid priority. Must be one of: \(validPriorities.joined(separator: ", "))",
                type: "InvalidPriority",
                isNonRetryable: true
            )
        }

        // Cannot change priority after shipping has started
        guard
            currentState != "shipping" && currentState != "notifying"
                && currentState != "completed"
        else {
            throw ApplicationError(
                message: "Cannot change priority after shipping has started",
                type: "InvalidState",
                isNonRetryable: true
            )
        }

        let oldPriority = priority
        priority = input.priority
        return "Priority changed from \(oldPriority) to \(priority)"
    }

    // MARK: - Helper Methods

    private func cancelledOutput() -> OrderOutput {
        return OrderOutput(
            orderId: orderId,
            status: "cancelled",
            processedId: nil,
            trackingNumber: nil,
            priority: priority
        )
    }
}
