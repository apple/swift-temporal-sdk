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

func withInterceptors<Interceptor: Sendable, Input: Sendable, Result: Sendable>(
    _ interceptors: [Interceptor],
    input: Input,
    call: (Interceptor) -> (Input, (Input) -> Result) -> Result,
    original: (Input) -> Result
) -> Result {
    var iterator = interceptors.makeIterator()
    func iterate(input: Input, iterator: inout [Interceptor].Iterator) -> Result {
        guard let interceptor = iterator.next() else {
            return original(input)
        }

        return call(interceptor)(input) {
            return iterate(input: $0, iterator: &iterator)
        }
    }

    return iterate(input: input, iterator: &iterator)
}

func withInterceptors<Interceptor: Sendable, Input: Sendable, Result: Sendable>(
    _ interceptors: [Interceptor],
    input: Input,
    call: (Interceptor) -> (Input, (Input) throws -> Result) throws -> Result,
    original: (Input) throws -> Result
) throws -> Result {
    var iterator = interceptors.makeIterator()
    func iterate(input: Input, iterator: inout [Interceptor].Iterator) throws -> Result {
        guard let interceptor = iterator.next() else {
            return try original(input)
        }

        return try call(interceptor)(input) {
            return try iterate(input: $0, iterator: &iterator)
        }
    }

    return try iterate(input: input, iterator: &iterator)
}

func withInterceptors<Interceptor: Sendable, Input: Sendable, Result: Sendable>(
    _ interceptors: [Interceptor],
    input: Input,
    call: (Interceptor) -> (Input, (Input) async throws -> Result) async throws -> Result,
    original: (Input) async throws -> Result
) async throws -> Result {
    var iterator = interceptors.makeIterator()
    func iterate(input: Input, iterator: inout [Interceptor].Iterator) async throws -> Result {
        guard let interceptor = iterator.next() else {
            return try await original(input)
        }

        return try await call(interceptor)(input) {
            return try await iterate(input: $0, iterator: &iterator)
        }
    }

    return try await iterate(input: input, iterator: &iterator)
}

protocol InterceptorImplementation {
    associatedtype Interceptor: Sendable
    var interceptors: [Interceptor] { get }
}

extension InterceptorImplementation {
    func intercept<Input: Sendable, Result: Sendable>(
        _ call: (Interceptor) -> (Input, (Input) -> (Result)) -> Result,
        input: Input,
        original: (Input) -> Result
    ) -> Result {
        return withInterceptors(self.interceptors, input: input, call: call, original: original)
    }
    func intercept<Input: Sendable, Result: Sendable>(
        _ call: (Interceptor) -> (Input, (Input) throws -> (Result)) throws -> Result,
        input: Input,
        original: (Input) throws -> Result
    ) throws -> Result {
        return try withInterceptors(self.interceptors, input: input, call: call, original: original)
    }
    func intercept<Input: Sendable, Result: Sendable>(
        _ call: (Interceptor) -> (Input, (Input) async throws -> (Result)) async throws -> Result,
        input: Input,
        original: (Input) async throws -> Result
    ) async throws -> Result {
        return try await withInterceptors(self.interceptors, input: input, call: call, original: original)
    }
}
