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

/// Protocol for a client interceptor.
public protocol ClientInterceptor: Sendable {
    /// The type of client outbound interceptor created by this interceptor.
    associatedtype ClientOutboundInterceptorType: ClientOutboundInterceptor = ForwardingClientOutboundInterceptor

    /// The client outbound interceptor for intercepting and modifying client operations, or `nil` if no interception is needed.
    var clientOutboundInterceptor: ClientOutboundInterceptorType? { get }
}

extension ClientInterceptor {
    /// Default implementation that returns no client outbound interceptor.
    public var clientOutboundInterceptor: ClientOutboundInterceptorType? { nil }
}

/// A client outbound interceptor that forwards all operations to the next interceptor in the chain.
public struct ForwardingClientOutboundInterceptor: ClientOutboundInterceptor {}
