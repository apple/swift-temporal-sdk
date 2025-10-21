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

#if canImport(FoundationEssentials)
package import FoundationEssentials
#else
package import Foundation
#endif

/// Paginates a network call by sequentially retrieving full response pages.
///
/// Automates pagination for network calls by repeatedly invoking the client request. In each iteration, the provided `clientCall` closure receives a
/// `pageToken`  (an empty token for the first request) and returns a tuple containing the complete response and the next page token.
/// The resulting `AsyncSequence` yields each full response page, without flattening the response elements.
///
/// The specified `clientCall` closure receives a page token (an empty token is passed for the initial page) and must return a tuple containing:
///     - the complete response page
///     - the next page token
///
/// If the next page token is empty, pagination terminates.
///
/// The resulting sequence can be further transformed using standard `AsyncSequence` methods such as `map(_:)`.
///
/// ### Example
///
/// An example of how ``withPagination(_:)`` can be used in practice with a gRPC request via `grpc-swift` can be found here:
///
/// ```swift
/// withPagination { pageToken in
///     let response = try await client.listXYZ(
///         .with {
///             $0.maximumPageSize = 100    // maximum page size of a single response
///             $0.nextPageToken = pageToken    // page token provided by `withPagination(_:)`
///         },
///         metadata: [:],  // optional gRPC metadata
///         options: .default   // optional gRPC call options
///     )
///
///     // return the response page along with the next page token
///     return (response: response, pageToken: response.nextPageToken)
/// }
/// ```
///
/// - Parameters:
///   - clientCall: A closure that takes a page token (from the previous response or empty), executes the network request using that token, and returns a tuple containing the complete response page and the next page token.
///
/// - Returns: An `AsyncSequence` that yields one complete response page per iteration.
package func withPagination<Response: Sendable>(
    _ clientCall: @Sendable @escaping (_ pageToken: Data) async throws -> (response: Response, pageToken: Data)
) -> some (AsyncSequence<Response, any Error> & Sendable) {
    PaginatedResponseSequence(clientCall: clientCall)
}

/// Paginate a network call and yield individual response elements.
///
/// Automates pagination for network calls by repeatedly invoking the client request. In each iteration, the provided `clientCall` closure receives a
/// `pageToken`  (an empty token for the first request) and returns a tuple containing the response element collection and the next page token.
/// It then flattens each page’s collection of elements so that the returned `AsyncSequence` yields them one at a time.
///
/// The specified `clientCall` closure receives a page token (an empty token is passed for the initial page) and must return a tuple containing:
///     - a collection of response elements extracted from the overall response
///     - the next page token
///
/// If the next page token is empty, pagination terminates.
///
/// The resulting sequence can be further transformed using standard `AsyncSequence` methods such as `map(_:)`.
///
/// ### Example
///
/// An example of how ``withFlattenedPagination(_:)`` can be used in practice with a gRPC request via `grpc-swift`:
///
/// ```swift
/// withFlattenedPagination { pageToken in
///     let response = try await client.listXYZ(    // the paginated gRPC network request
///         .with {
///             $0.maximumPageSize = 100    // maximum page size of a single response
///             $0.nextPageToken = pageToken    // page token provided by `withFlattenedPagination(_:)`
///         },
///         metadata: [:],  // optional gRPC metadata
///         options: .default   // optional gRPC call options
///     )
///
///     // return the response elements along with the next page token
///     return (elements: response.elements, pageToken: response.nextPageToken)
/// }
/// ```
///
/// - Parameters:
///   - clientCall: A closure that takes a page token (from the previous response or empty), executes the network request using that token, and returns a tuple containing a collection of response elements and the next page token.
///
/// - Returns: An `AsyncSequence` that yields individual response `Element`s as it paginates.
package func withFlattenedPagination<Element: Sendable>(
    _ clientCall: @Sendable @escaping (_ pageToken: Data) async throws -> (elements: some Collection<Element> & Sendable, pageToken: Data)
) -> some (AsyncSequence<Element, any Error> & Sendable) {
    PaginatedResponseSequence(clientCall: clientCall)
        .flattened()
}
