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

/// Protocol for intercepting and modifying workflow execution requests from the Temporal server before they
/// reach workflow implementations.
public protocol WorkflowInboundInterceptor: Sendable {
    /// Intercepts workflow execution requests from the Temporal server.
    ///
    /// - Parameters:
    ///   - input: The workflow execution input containing workflow details and parameters.
    ///   - next: A closure to invoke the next interceptor in the chain.
    /// - Returns: The output produced by the workflow execution.
    /// - Throws: Any error that occurs during workflow execution or interception.
    func executeWorkflow<Workflow>(
        input: ExecuteWorkflowInput<Workflow>,
        next: (ExecuteWorkflowInput<Workflow>) async throws -> Workflow.Output
    ) async throws -> Workflow.Output

    /// Intercepts workflow signal handling requests from the Temporal server.
    ///
    /// - Parameters:
    ///   - input: The signal handling input containing signal details and payload.
    ///   - next: A closure to invoke the next interceptor in the chain.
    /// - Throws: Any error that occurs during signal handling or interception.
    func handleSignal<Signal>(
        input: HandleSignalInput<Signal>,
        next: (HandleSignalInput<Signal>) async throws -> Void
    ) async throws

    /// Intercepts workflow query requests from the Temporal server.
    ///
    /// - Parameters:
    ///   - input: The query handling input containing query details and parameters.
    ///   - next: A closure to invoke the next interceptor in the chain.
    /// - Returns: The result of the workflow query.
    /// - Throws: Any error that occurs during query processing or interception.
    func handleQuery<Query>(
        input: HandleQueryInput<Query>,
        next: (HandleQueryInput<Query>) throws -> Query.Output
    ) throws -> Query.Output

    /// Intercepts workflow update requests from the Temporal server.
    ///
    /// - Parameters:
    ///   - input: The update handling input containing update details and parameters.
    ///   - next: A closure to invoke the next interceptor in the chain.
    /// - Returns: The result of the workflow update.
    /// - Throws: Any error that occurs during update processing or interception.
    func handleUpdate<Update>(
        input: HandleUpdateInput<Update>,
        next: (HandleUpdateInput<Update>) async throws -> Update.Output
    ) async throws -> Update.Output

    /// Intercepts workflow update validation requests from the Temporal server.
    ///
    /// - Parameters:
    ///   - input: The update validation input containing update details for validation.
    ///   - next: A closure to invoke the next interceptor in the chain.
    /// - Throws: Validation errors that prevent update execution.
    func validateUpdate<Update>(
        input: HandleUpdateInput<Update>,
        next: (HandleUpdateInput<Update>) throws -> Void
    ) throws
}

extension WorkflowInboundInterceptor {
    /// Default implementation that forwards workflow execution to the next interceptor without modification.
    ///
    /// - Parameters:
    ///   - input: The workflow execution input containing workflow details and parameters.
    ///   - next: A closure to invoke the next interceptor in the chain.
    /// - Returns: The output produced by the workflow execution.
    /// - Throws: Any error that occurs during workflow execution or interception.
    public func executeWorkflow<Workflow>(
        input: ExecuteWorkflowInput<Workflow>,
        next: (ExecuteWorkflowInput<Workflow>) async throws -> Workflow.Output
    ) async throws -> Workflow.Output {
        try await next(input)
    }

    /// Default implementation that forwards signal handling to the next interceptor without modification.
    ///
    /// - Parameters:
    ///   - input: The signal handling input containing signal details and payload.
    ///   - next: A closure to invoke the next interceptor in the chain.
    /// - Throws: Any error that occurs during signal handling or interception.
    public func handleSignal<Signal>(
        input: HandleSignalInput<Signal>,
        next: (HandleSignalInput<Signal>) async throws -> Void
    ) async throws {
        try await next(input)
    }

    /// Default implementation that forwards query handling to the next interceptor without modification.
    ///
    /// - Parameters:
    ///   - input: The query handling input containing query details and parameters.
    ///   - next: A closure to invoke the next interceptor in the chain.
    /// - Returns: The result of the workflow query.
    /// - Throws: Any error that occurs during query processing or interception.
    public func handleQuery<Query>(
        input: HandleQueryInput<Query>,
        next: (HandleQueryInput<Query>) throws -> Query.Output
    ) throws -> Query.Output {
        try next(input)
    }

    /// Default implementation that forwards update handling to the next interceptor without modification.
    ///
    /// - Parameters:
    ///   - input: The update handling input containing update details and parameters.
    ///   - next: A closure to invoke the next interceptor in the chain.
    /// - Returns: The result of the workflow update.
    /// - Throws: Any error that occurs during update processing or interception.
    public func handleUpdate<Update>(
        input: HandleUpdateInput<Update>,
        next: (HandleUpdateInput<Update>) async throws -> Update.Output
    ) async throws -> Update.Output {
        try await next(input)
    }

    /// Default implementation that forwards update validation to the next interceptor without modification.
    ///
    /// - Parameters:
    ///   - input: The update validation input containing update details for validation.
    ///   - next: A closure to invoke the next interceptor in the chain.
    /// - Throws: Validation errors that prevent update execution.
    public func validateUpdate<Update>(
        input: HandleUpdateInput<Update>,
        next: (HandleUpdateInput<Update>) throws -> Void
    ) throws {
        try next(input)
    }
}
