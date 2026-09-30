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

/// A plugin that customizes a ``TemporalClient`` before it connects to the server.
///
/// A client plugin can append interceptors, swap the data converter, set the namespace or API key,
/// or adjust any other field on ``TemporalClient/Configuration``. Each plugin's ``configure(_:)``
/// method runs against a mutable ``TemporalClient/Configuration`` before the client connects, in
/// the order the plugins appear in ``TemporalClient/Configuration/plugins``.
///
/// ## Implementing a plugin
///
/// Conform to ``ClientPlugin`` and override only the requirements you need. The protocol provides
/// a default ``name`` derived from the conforming type and a no-op default for
/// ``configure(_:)`` so simple plugins remain a few lines:
///
/// ```swift
/// struct AuthPlugin: ClientPlugin {
///     let token: String
///
///     func configure(_ configuration: inout TemporalClient.Configuration) {
///         configuration.apiKey = token
///     }
/// }
/// ```
///
/// ## Relationship to interceptors
///
/// An interceptor wraps each outbound call at runtime, while a plugin runs once at configuration
/// time. A plugin can contribute interceptors by appending them to
/// ``TemporalClient/Configuration/interceptors`` during ``configure(_:)``.
///
/// ## Wrapping the connected client lifetime
///
/// A plugin can also observe and surround the lifetime of a connected client by overriding
/// ``connectClient(configuration:next:)``. The method receives the merged configuration and a
/// continuation closure, and is expected to invoke the continuation as part of its body. Wrapping
/// is useful for emitting telemetry around connect/disconnect, mapping errors, or running setup
/// and teardown that should bracket the client's connected state. When plugins compose, the first
/// plugin in ``TemporalClient/Configuration/plugins`` is the outermost wrap.
public protocol ClientPlugin: Sendable {
    /// A human-readable name used in diagnostics and ordering.
    ///
    /// Defaults to the conforming type's name. Override to disambiguate multiple plugins of the
    /// same type or to provide a stable identifier for logs.
    var name: String { get }

    /// Customizes a client configuration before the client connects.
    ///
    /// Implementations mutate `configuration` in place to adjust fields such as
    /// ``TemporalClient/Configuration/namespace``, ``TemporalClient/Configuration/dataConverter``,
    /// ``TemporalClient/Configuration/interceptors``, or ``TemporalClient/Configuration/apiKey``.
    /// The mutated configuration is then handed to the next plugin in the chain, and finally to
    /// the client at connect time.
    ///
    /// - Parameter configuration: The configuration to customize.
    func configure(_ configuration: inout TemporalClient.Configuration)

    /// Wraps the lifetime of a connected client.
    ///
    /// The default implementation forwards through to `next`, so plugins that do not need to
    /// surround the connected lifetime can omit this method. Override to bracket the connected
    /// client with custom logic, such as logging, metrics, or error mapping. Implementations must
    /// invoke `next` exactly once and return whatever value it produces, so the value returned by
    /// the public connect API is preserved. Calling `next` zero times or more than once is
    /// undefined behavior; the SDK reserves the right to detect and reject it in a future release.
    ///
    /// When the configuration carries multiple plugins, the first plugin in
    /// ``TemporalClient/Configuration/plugins`` is the outermost wrap and the last plugin is the
    /// innermost. The continuation closure invokes the next plugin in the chain, and ultimately
    /// the gRPC connection plus the body supplied to the public connect entry point.
    ///
    /// The wrap scope differs between the two public client entry points:
    /// - ``TemporalClient/connect(transport:configuration:logger:_:)`` brackets the entire gRPC
    ///   client lifetime, including transport open and close.
    /// - For the two-phase ``TemporalClient`` `Service` API (init then `run()`), the wrap brackets
    ///   the `run()` call only — the gRPC client is constructed by the init step before any plugin
    ///   sees it.
    ///
    /// - Parameters:
    ///   - configuration: The merged configuration the client is about to use. Plugins receive
    ///     the configuration after every plugin's ``configure(_:)`` has run.
    ///   - next: A continuation that, when invoked, runs the rest of the plugin chain and the
    ///     underlying connected work. Returns the value produced by the public connect entry point.
    /// - Returns: The value produced by `next`, optionally transformed by the plugin.
    func connectClient<R: Sendable>(
        configuration: TemporalClient.Configuration,
        next: () async throws -> sending R
    ) async throws -> sending R
}

extension ClientPlugin {
    public var name: String {
        String(describing: Self.self)
    }

    public func configure(_ configuration: inout TemporalClient.Configuration) {}

    public func connectClient<R: Sendable>(
        configuration: TemporalClient.Configuration,
        next: () async throws -> sending R
    ) async throws -> sending R {
        try await next()
    }
}
