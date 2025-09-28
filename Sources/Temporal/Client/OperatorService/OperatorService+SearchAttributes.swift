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

import struct GRPCCore.CallOptions

extension TemporalClient.OperatorService {
    /// Adds custom search attributes to enable advanced workflow querying.
    ///
    /// Custom search attributes extend Temporal's querying capabilities by allowing
    /// you to index workflow metadata beyond the system-provided attributes. This
    /// method accepts strongly-typed search attribute keys and registers them with
    /// the Temporal cluster for use in visibility queries.
    ///
    /// - Parameters:
    ///   - namespace: The namespace in which to add the search attributes. Uses configuration namespace if nil.
    ///   - attributes: Variadic parameter pack of strongly-typed search attribute keys to register.
    ///   - callOptions: Optional gRPC call options for customizing the behavior of the underlying request.
    /// - Throws: An error if attribute registration fails, names conflict, or access is denied.
    public func addSearchAttributes<each Value>(
        namespace: String? = nil,
        _ attributes: repeat SearchAttributeKey<each Value>,
        callOptions: CallOptions? = nil
    ) async throws {
        var searchAttributes = [String: Temporal_Api_Enums_V1_IndexedValueType]()
        for attribute in repeat each attributes {
            searchAttributes[attribute.name] = .init(attribute.type)
        }

        try await self.client.unary(
            method: Temporal_Api_Operatorservice_V1_OperatorService.Method.AddSearchAttributes.descriptor,
            request: Temporal_Api_Operatorservice_V1_AddSearchAttributesRequest.with {
                $0.namespace = configuration.namespace
                $0.searchAttributes = searchAttributes
            },
            callOptions: callOptions
        )
    }

    /// Adds custom search attributes from a collection of type-erased keys.
    ///
    /// This overload accepts an array of ``AnySearchAttributeKey`` instances, allowing
    /// for dynamic search attribute registration when the attribute types are not
    /// known at compile time. This is useful for configuration-driven attribute setup
    /// or when integrating with external systems.
    ///
    /// - Parameters:
    ///   - namespace: The namespace in which to add the search attributes. Uses configuration namespace if nil.
    ///   - attributes: Array of type-erased search attribute keys to register.
    ///   - callOptions: Optional gRPC call options for customizing the behavior of the underlying request.
    /// - Throws: An error if attribute registration fails, names conflict, or access is denied.
    public func addSearchAttributes(
        namespace: String? = nil,
        _ attributes: [AnySearchAttributeKey],
        callOptions: CallOptions? = nil
    ) async throws {
        var searchAttributes = [String: Temporal_Api_Enums_V1_IndexedValueType]()
        for attribute in attributes {
            searchAttributes[attribute.name] = .init(attribute.type)
        }

        try await self.client.unary(
            method: Temporal_Api_Operatorservice_V1_OperatorService.Method.AddSearchAttributes.descriptor,
            request: Temporal_Api_Operatorservice_V1_AddSearchAttributesRequest.with {
                $0.namespace = configuration.namespace
                $0.searchAttributes = searchAttributes
            },
            callOptions: callOptions
        )
    }

    /// Removes custom search attributes from the namespace configuration.
    ///
    /// This method removes search attribute definitions from the Temporal namespace,
    /// preventing their use in new workflow queries and indexing operations. The
    /// removal is immediate and affects all future workflow executions, though
    /// existing workflow data may retain indexed values until archival.
    ///
    /// - Parameters:
    ///   - namespace: The namespace from which to remove the search attributes. Uses configuration namespace if nil.
    ///   - attributes: Variadic parameter pack of search attribute keys to remove.
    ///   - callOptions: Optional gRPC call options for customizing the behavior of the underlying request.
    /// - Throws: An error if removal fails, attributes don't exist, or access is denied.
    public func removeSearchAttributes<each Value>(
        namespace: String? = nil,
        _ attributes: repeat SearchAttributeKey<each Value>,
        callOptions: CallOptions? = nil
    ) async throws {
        var searchAttributes = [String]()
        for attribute in repeat each attributes {
            searchAttributes.append(attribute.name)
        }

        try await self.client.unary(
            method: Temporal_Api_Operatorservice_V1_OperatorService.Method.RemoveSearchAttributes.descriptor,
            request: Temporal_Api_Operatorservice_V1_RemoveSearchAttributesRequest.with {
                $0.namespace = configuration.namespace
                $0.searchAttributes = searchAttributes
            },
            callOptions: callOptions
        )
    }

    /// Removes custom search attributes using type-erased attribute keys.
    ///
    /// This overload accepts an array of ``AnySearchAttributeKey`` instances for
    /// dynamic search attribute removal. This is particularly useful when building
    /// administrative tools or when the attributes to remove are determined at runtime
    /// based on configuration or user input.
    ///
    /// - Parameters:
    ///   - namespace: The namespace from which to remove the search attributes. Uses configuration namespace if nil.
    ///   - attributes: Array of type-erased search attribute keys to remove.
    ///   - callOptions: Optional gRPC call options for customizing the behavior of the underlying request.
    /// - Throws: An error if removal fails, attributes don't exist, or access is denied.
    public func removeSearchAttributes(
        namespace: String? = nil,
        _ attributes: [AnySearchAttributeKey],
        callOptions: CallOptions? = nil
    ) async throws {
        var searchAttributes = [String]()
        for attribute in attributes {
            searchAttributes.append(attribute.name)
        }

        try await self.client.unary(
            method: Temporal_Api_Operatorservice_V1_OperatorService.Method.RemoveSearchAttributes.descriptor,
            request: Temporal_Api_Operatorservice_V1_RemoveSearchAttributesRequest.with {
                $0.namespace = configuration.namespace
                $0.searchAttributes = searchAttributes
            },
            callOptions: callOptions
        )
    }

    /// Returns comprehensive information about available search attributes.
    ///
    /// Search attributes enable complex workflow queries by indexing workflow metadata.
    /// This method retrieves detailed information about all search attributes available
    /// in the specified namespace, including system-defined attributes (built into Temporal)
    /// and custom attributes that have been added by administrators.
    ///
    /// - Parameters:
    ///    - namespace: The namespace from which to retrieve search attributes. Uses configuration namespace if `nil`.
    ///    - callOptions: Optional gRPC call options for customizing the behavior of the underlying request.
    /// - Returns: A ``SearchAttributeKeyCollection`` containing comprehensive search attribute information.
    /// - Throws: An error if the operation fails or access is denied.
    public func listSearchAttributes(namespace: String? = nil, callOptions: CallOptions? = nil) async throws -> SearchAttributeKeyCollection {
        let response: Temporal_Api_Operatorservice_V1_ListSearchAttributesResponse = try await self.client.unary(
            method: Temporal_Api_Operatorservice_V1_OperatorService.Method.ListSearchAttributes.descriptor,
            request: Temporal_Api_Operatorservice_V1_ListSearchAttributesRequest.with {
                $0.namespace = configuration.namespace
            },
            callOptions: callOptions
        )

        return .init(proto: response)
    }
}
