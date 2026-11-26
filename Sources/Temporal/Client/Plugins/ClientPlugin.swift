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

/// A plugin that customizes a ``TemporalClient`` before it connects, and can wrap the connected
/// client's lifetime.
///
/// Each plugin's ``configureClient(_:)`` runs against the ``TemporalClient/Configuration`` before
/// the client connects, in the order the plugins appear in
/// ``TemporalClient/Configuration/plugins``. A plugin can append interceptors, replace the data
/// converter, or set any other field except ``TemporalClient/Configuration/plugins``.
///
/// ## Implementing a plugin
///
/// Implement only the requirements you need; the others have defaults:
///
/// ```swift
/// struct AuthPlugin: ClientPlugin {
///     let token: String
///
///     func configureClient(_ configuration: inout TemporalClient.Configuration) {
///         configuration.apiKey = token
///     }
/// }
/// ```
///
/// ## Relationship to interceptors
///
/// An interceptor runs once per request, while a plugin's ``configureClient(_:)`` runs once, at
/// configuration time. A plugin can contribute interceptors by appending them to
/// ``TemporalClient/Configuration/interceptors`` in ``configureClient(_:)``.
///
/// - Important: This is currently experimental and may be removed or changed in the future.
public protocol ClientPlugin: TemporalPlugin {
    /// Customizes a client configuration before the client connects.
    ///
    /// The mutated configuration is passed to the next plugin, and finally to the client.
    ///
    /// - Parameter configuration: The configuration to customize.
    func configureClient(_ configuration: inout TemporalClient.Configuration)

    /// Wraps the lifetime of a connected client.
    ///
    /// Implementations must invoke `next` exactly once and return the value it produces. The
    /// default implementation only calls `next`. When several plugins are set, the first in
    /// ``TemporalClient/Configuration/plugins`` is the outermost wrap.
    ///
    /// The scope depends on how the client is created:
    /// - With ``TemporalClient/connect(transport:configuration:_:)``, the wrap covers the
    ///   whole connected lifetime, including opening and closing the transport, and the body passed
    ///   to `connect`.
    /// - ``TemporalClient/init(transport:configuration:)`` builds the gRPC client right
    ///   away, so the wrap covers ``TemporalClient/run()`` only.
    ///
    /// - Important: Copy this signature exactly, including `nonisolated(nonsending)` and both
    ///   `sending` keywords. Otherwise the default implementation can silently run instead.
    ///
    /// - Parameters:
    ///   - configuration: The configuration after every plugin's ``configureClient(_:)`` has run.
    ///   - next: Runs the rest of the plugin chain and then the connected work.
    /// - Returns: The value produced by `next`.
    nonisolated(nonsending) func connectClient<R: Sendable>(
        configuration: TemporalClient.Configuration,
        next: nonisolated(nonsending) () async throws -> sending R
    ) async throws -> sending R
}

extension ClientPlugin {
    public func configureClient(_ configuration: inout TemporalClient.Configuration) {}

    public nonisolated(nonsending) func connectClient<R: Sendable>(
        configuration: TemporalClient.Configuration,
        next: nonisolated(nonsending) () async throws -> sending R
    ) async throws -> sending R {
        try await next()
    }
}
