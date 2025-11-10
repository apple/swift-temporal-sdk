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

/// A protocol for defining Temporal workflow signals.
///
/// Workflow signals provide a way to asynchronously send messages to running workflows,
/// allowing external systems to trigger specific behavior or state changes within the workflow.
/// Signals are fire-and-forget operations that don't return values to the sender.
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
/// final class OrderProcessingWorkflow {
///     var approvalReceived = false
///
///     func run(input: OrderInput) async throws -> Void {
///         // Wait for approval signal
///         try await context.condition { approvalReceived }
///
///         // Process the order
///         try await processOrder()
///     }
///
///     @WorkflowSignal
///     func approveOrder() async throws {
///         self.approvalReceived = true
///     }
/// }
/// ```
public protocol WorkflowSignalDefinition<Workflow>: Sendable {
    /// The input type for the signal.
    associatedtype Input: Sendable

    /// The workflow type that this signal can be sent to.
    associatedtype Workflow: WorkflowDefinition

    /// The signal name used for identification and routing.
    ///
    /// This identifier is used by Temporal to route signal requests to the appropriate implementation.
    /// Defaults to the string representation of the conforming type.
    static var name: String { get }

    /// An optional description of the signal's purpose.
    ///
    /// This description may appear in user interfaces and tooling to help
    /// users understand the signal's functionality. Defaults to `nil`.
    static var description: String? { get }

    /// Executes the signal handler logic.
    ///
    /// This method is called when a signal is received by the workflow.
    /// Use ``Workflow`` static methods to access workflow operations.
    ///
    /// - Parameters:
    ///   - workflow: The workflow instance receiving the signal.
    ///   - input: The input data sent with the signal.
    /// - Throws: Any error that occurs during signal processing.
    func run(workflow: Workflow, input: Input) async throws
}

extension WorkflowSignalDefinition {
    /// Default implementation returning the type name as the signal name.
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
