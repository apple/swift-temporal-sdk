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

public import GRPCCore

extension TemporalClient {
    /// Provides access to Temporal operator services for administrative operations.
    public struct OperatorService: Sendable {
        /// The configuration of the ``TemporalClient``.
        package let configuration: TemporalClient.Configuration
        let client: TemporalClient.ConfiguredClient
        let metadata: GRPCCore.Metadata

        /// Initializes a new Temporal operator client for accessing operator services.
        ///
        /// - Parameters:
        ///   - client: A type-erased, configured `GRPCClient` used for performing RPCs.
        ///   - configuration: The configuration of the Temporal client including namespace and identity.
        ///   - metadata: Metadata set on the client for request context and authentication.
        init(
            client: TemporalClient.ConfiguredClient,
            configuration: TemporalClient.Configuration,
            metadata: GRPCCore.Metadata
        ) {
            self.client = client
            self.configuration = configuration
            self.metadata = metadata
        }
    }

    // MARK: List Workflows

    /// Returns a sequence of workflow executions matching the given query.
    ///
    /// This method provides access to workflow listing functionality through the client's
    /// operator service. It uses Temporal's visibility query language to filter workflow
    /// executions and returns results as an async sequence for efficient processing of large
    /// result sets.
    ///
    /// - Parameters:
    ///   - query: The visibility query to match workflow executions against using Temporal's query syntax.
    ///   - limit: The maximum number of results to return. If nil, returns all matching results.
    ///   - callOptions: Optional gRPC call options for customizing the behavior of the underlying request.
    /// - Returns: An `AsyncSequence` of `WorkflowExecution`s matching the query criteria.
    /// - Throws: An error if the query is malformed or the operation fails.
    public func listWorkflows(
        query: String,
        limit: Int? = nil,
        callOptions: CallOptions? = nil
    ) async throws -> some AsyncSequence<WorkflowExecution, any Error> & Sendable {
        try await self.interceptor.listWorkflows(
            .init(
                query: query,
                limit: limit,
                callOptions: callOptions
            )
        )
    }

    /// Counts workflow executions matching the given query.
    ///
    /// This method returns the total number of workflow executions that match the
    /// specified visibility query without actually retrieving the execution details.
    /// This is useful for pagination calculations and determining result set sizes
    /// without the overhead of transferring full execution data.
    ///
    /// - Parameters:
    ///   - query: The visibility query to match workflow executions against.
    ///   - callOptions: Optional gRPC call options for customizing the behavior of the underlying request.
    /// - Returns: A ``WorkflowExecutionCount`` containing the number of matching executions.
    /// - Throws: An error if the query is malformed or the operation fails.
    public func countWorkflows(
        query: String,
        callOptions: CallOptions? = nil
    ) async throws -> WorkflowExecutionCount {
        try await self.interceptor.countWorkflows(
            .init(
                query: query,
                callOptions: callOptions
            )
        )
    }

    // MARK: Search Attributes

    /// Returns a breakdown of custom and system search attributes.
    ///
    /// Search attributes enable complex workflow queries by indexing workflow metadata.
    /// This method retrieves all available search attributes for the specified namespace,
    /// including both system-defined attributes (built into Temporal) and custom attributes
    /// that have been added by administrators.
    ///
    /// - Parameters:
    ///    - namespace: The namespace from which to list search attributes. If nil, uses the client's default namespace.
    ///    - callOptions: Optional gRPC call options for customizing the behavior of the underlying request.
    /// - Returns: A ``SearchAttributeKeyCollection`` containing custom, system, and storage schema information.
    /// - Throws: An error if the operation fails or access is denied.
    public func listSearchAttributes(namespace: String? = nil, callOptions: CallOptions? = nil) async throws -> SearchAttributeKeyCollection {
        try await self.operatorService.listSearchAttributes(
            namespace: namespace,
            callOptions: callOptions
        )
    }

    /// Adds custom search attributes to enable advanced workflow querying.
    ///
    /// Custom search attributes allow you to index workflow metadata beyond the
    /// system-provided attributes. Once added, these attributes can be used in
    /// visibility queries to filter and search workflows based on domain-specific data.
    ///
    /// - Parameters:
    ///   - namespace: The namespace in which to add the search attributes. If nil, uses the client's default namespace.
    ///   - attributes: The variadic list of strongly-typed search attribute keys to add.
    ///   - callOptions: Optional gRPC call options for customizing the behavior of the underlying request.
    /// - Throws: An error if the operation fails, attributes already exist, or access is denied.
    public func addSearchAttributes<each Value>(
        namespace: String? = nil,
        _ attributes: repeat SearchAttributeKey<each Value>,
        callOptions: CallOptions? = nil
    ) async throws {
        try await self.operatorService.addSearchAttributes(
            namespace: namespace,
            repeat each attributes,
            callOptions: callOptions
        )
    }

    /// Removes custom search attributes from the namespace configuration.
    ///
    /// This operation removes the search attribute definitions from the namespace,
    /// preventing their use in new workflow queries. Existing workflows that have
    /// already used these attributes may retain the indexed data until they complete.
    ///
    /// - Parameters:
    ///   - namespace: The namespace from which to remove the search attributes. If nil, uses the client's default namespace.
    ///   - attributes: The variadic list of search attribute keys to remove.
    ///   - callOptions: Optional gRPC call options for customizing the behavior of the underlying request.
    /// - Throws: An error if the operation fails, attributes don't exist, or access is denied.
    public func removeSearchAttributes<each Value>(
        namespace: String? = nil,
        _ attributes: repeat SearchAttributeKey<each Value>,
        callOptions: CallOptions? = nil
    ) async throws {
        try await self.operatorService.removeSearchAttributes(
            namespace: namespace,
            repeat each attributes,
            callOptions: callOptions
        )
    }
}

extension TemporalClient.Interceptor {
    package func listWorkflows(
        _ input: ListWorkflowsInput
    ) async throws -> some AsyncSequence<WorkflowExecution, any Error> & Sendable {
        try await self.intercept((any ClientOutboundInterceptor).listWorkflows, input: input) { input in
            try await self.workflowService.listWorkflowExecutions(
                query: input.query,
                limit: input.limit,
                callOptions: input.callOptions
            )
        }
    }

    package func countWorkflows(
        _ input: CountWorkflowsInput
    ) async throws -> WorkflowExecutionCount {
        try await self.intercept((any ClientOutboundInterceptor).countWorkflows, input: input) { input in
            try await self.workflowService.countWorkflowExecutions(
                input: input,
                callOptions: input.callOptions
            )
        }
    }
}
