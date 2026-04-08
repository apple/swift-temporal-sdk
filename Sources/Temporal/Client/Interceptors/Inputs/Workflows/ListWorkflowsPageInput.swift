//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Temporal SDK open source project
//
// Copyright (c) 2026 Apple Inc. and the Swift Temporal SDK project authors
// Licensed under MIT License
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Swift Temporal SDK project authors
//
// SPDX-License-Identifier: MIT
//
//===----------------------------------------------------------------------===//

public import struct GRPCCore.CallOptions

#if canImport(FoundationEssentials)
public import FoundationEssentials
#else
public import Foundation
#endif

/// Input parameters for fetching a single page of workflow executions in client interceptors.
public struct ListWorkflowsPageInput: Sendable {
    /// The query string to filter workflow executions using Temporal's visibility query language.
    public var query: String

    /// Optional maximum number of workflow executions to return per page.
    public var pageSize: Int?

    /// The token to retrieve the next page of results.
    ///
    /// Pass empty `Data` for the first page.
    public var nextPageToken: Data

    /// Optional gRPC call options for customizing the listing request.
    public var callOptions: CallOptions?

    /// Creates a new list workflows page input with the specified parameters.
    ///
    /// - Parameters:
    ///   - query: The query string to filter workflow executions using the visibility query language.
    ///   - pageSize: Optional maximum number of workflow executions to return per page.
    ///   - nextPageToken: The token to retrieve the next page of results. Pass empty `Data` for the first page.
    ///   - callOptions: Optional gRPC call options for customizing the request.
    public init(
        query: String,
        pageSize: Int? = nil,
        nextPageToken: Data = Data(),
        callOptions: CallOptions? = nil
    ) {
        self.query = query
        self.pageSize = pageSize
        self.nextPageToken = nextPageToken
        self.callOptions = callOptions
    }
}
