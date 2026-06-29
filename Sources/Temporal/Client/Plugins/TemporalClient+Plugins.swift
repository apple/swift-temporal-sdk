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

public import Logging

extension TemporalClient.Configuration {
    /// Applies the plugins set on ``TemporalClient/Configuration/plugins`` to this configuration in order.
    ///
    /// Each plugin's ``ClientPlugin/configure(_:)`` runs against the same configuration value, so
    /// later plugins observe and can build on the changes made by earlier ones. The plugin list is
    /// captured before the first plugin runs, so a plugin that mutates ``TemporalClient/Configuration/plugins``
    /// during its own `configure(_:)` does not affect the sequence applied in this call.
    ///
    /// Called automatically by ``TemporalClient/connect(transport:configuration:logger:_:)`` and
    /// ``TemporalClient/init(transport:configuration:logger:)``.
    ///
    /// - Parameter logger: The logger used to emit one `debug` entry per applied plugin, tagged
    ///   with the plugin's ``ClientPlugin/name``.
    ///
    /// - Note: This method is intended to be called exactly once per configuration value. Calling
    ///   it again would re-run each plugin against the already-mutated configuration and duplicate
    ///   any appended state such as interceptors.
    package mutating func applyPlugins(logger: Logger) {
        let plugins = self.plugins
        for plugin in plugins {
            logger.debug("Applying client plugin", metadata: [LoggingKeys.pluginName: "\(plugin.name)"])
            plugin.configure(&self)
        }
    }
}
