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

import struct GRPCCore.CallOptions

extension TemporalClient.NamespaceService {
    /// Returns an asynchronous sequence of all namespaces in the Temporal cluster.
    ///
    /// This method provides a paginated listing of all namespaces available in the
    /// Temporal cluster, optionally including deleted namespaces. The results are
    /// returned as an async sequence that automatically handles pagination,
    /// allowing you to iterate through large numbers of namespaces efficiently.
    ///
    /// - Parameters:
    ///    - includeDeleted: If `true`, includes soft-deleted namespaces in the results.
    ///    - callOptions: Optional gRPC call options for customizing the behavior of the underlying request.
    /// - Returns: An async sequence of namespace descriptions that can be iterated over.
    /// - Throws: ``TemporalError`` if the listing operation fails or access is denied.
    public func listNamespaces(
        includeDeleted: Bool = false,
        callOptions: CallOptions? = nil
    ) async throws -> some (AsyncSequence<NamespaceDescription, Error> & Sendable) {
        withFlattenedPagination { pageToken in
            let response: Temporal_Api_Workflowservice_V1_ListNamespacesResponse = try await self.client.unary(
                method: Temporal_Api_Workflowservice_V1_WorkflowService.Method.ListNamespaces.descriptor,
                request: Temporal_Api_Workflowservice_V1_ListNamespacesRequest.with {
                    $0.namespaceFilter = .with {
                        $0.includeDeleted = includeDeleted
                    }
                    $0.pageSize = 100
                    $0.nextPageToken = pageToken
                },
                callOptions: callOptions
            )

            return (elements: response.namespaces, pageToken: response.nextPageToken)
        }.map {
            NamespaceDescription(proto: $0)
        }
    }
}
