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

/// Factory protocol that creates interceptors for client-side operations.
public protocol ClientInterceptor: Sendable {
    /// The type of client outbound interceptor created by this factory.
    associatedtype ClientOutboundInterceptorType: ClientOutboundInterceptor = ForwardingClientOutboundInterceptor

    /// Creates a client outbound interceptor for intercepting and modifying client operations.
    func makeClientOutboundInterceptor() -> ClientOutboundInterceptorType?
}

extension ClientInterceptor {
    /// Provides a default implementation that disables interception by returning `nil`.
    ///
    /// - Returns: `nil` to disable interception by default.
    public func makeClientOutboundInterceptor() -> ClientOutboundInterceptorType? { nil }
}

/// A client outbound interceptor that forwards all operations to the next interceptor in the chain.
public struct ForwardingClientOutboundInterceptor: ClientOutboundInterceptor {}
