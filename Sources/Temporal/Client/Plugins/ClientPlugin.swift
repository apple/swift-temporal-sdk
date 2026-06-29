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
}

extension ClientPlugin {
    public var name: String {
        String(describing: Self.self)
    }

    public func configure(_ configuration: inout TemporalClient.Configuration) {}
}
