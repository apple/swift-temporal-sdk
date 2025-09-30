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
import FoundationEssentials
#else
import Foundation
#endif

/// Paginated response sequence for paginated network requests.
struct PaginatedResponseSequence<Response: Sendable>: AsyncSequence, Sendable {
    typealias Element = Response
    typealias AsyncIterator = Iterator

    struct Iterator: AsyncIteratorProtocol {
        enum State {
            case initialRequest
            case hasNextPage(Data)
            case finished
        }

        private let clientCall: @Sendable (_ token: Data) async throws -> (response: Response, pageToken: Data)
        private var state: State

        init(clientCall: @Sendable @escaping (_ token: Data) async throws -> (response: Response, pageToken: Data)) {
            self.clientCall = clientCall
            self.state = .initialRequest
        }

        mutating func next(isolation actor: isolated (any Actor)? = #isolation) async throws -> Response? {
            switch state {
            case .initialRequest:
                let (response, token) = try await clientCall(.init())
                updateState(with: token)
                return response

            case .hasNextPage(let token) where token.isEmpty:
                state = .finished
                return nil

            case .hasNextPage(let token):
                let (response, token) = try await clientCall(token)
                updateState(with: token)
                return response

            case .finished:
                return nil
            }
        }

        private mutating func updateState(with nextPageToken: Data) {
            if nextPageToken.isEmpty {
                state = .finished
            } else {
                state = .hasNextPage(nextPageToken)
            }
        }
    }

    private let clientCall: @Sendable (_ pageToken: Data) async throws -> (response: Response, pageToken: Data)

    init(clientCall: @Sendable @escaping (_ pageToken: Data) async throws -> (Response, pageToken: Data)) {
        self.clientCall = clientCall
    }

    func makeAsyncIterator() -> Iterator {
        Iterator(clientCall: clientCall)
    }
}
