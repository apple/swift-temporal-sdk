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

/// A plugin that customizes a ``TemporalClient`` before it connects.
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
}

extension ClientPlugin {
    public func configureClient(_ configuration: inout TemporalClient.Configuration) {}
}
