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

package import Logging

extension TemporalClient.Configuration {
    /// Applies ``TemporalClient/Configuration/plugins`` to this configuration, in order.
    ///
    /// Each plugin's ``ClientPlugin/configureClient(_:)`` sees the changes made by the plugins
    /// before it. The plugin list is captured before the first plugin runs and restored afterward,
    /// so a plugin that changes ``TemporalClient/Configuration/plugins`` has no effect.
    ///
    /// Called by ``TemporalClient/connect(transport:configuration:logger:_:)`` and
    /// ``TemporalClient/init(transport:configuration:logger:)``.
    ///
    /// - Parameter logger: Receives one `debug` entry per plugin, tagged with its
    ///   ``TemporalPlugin/name``.
    ///
    /// - Note: Call this once per configuration value. Calling it again re-runs every plugin and
    ///   duplicates anything they append, such as interceptors.
    package mutating func applyPlugins(logger: Logger) {
        let plugins = self.plugins
        for plugin in plugins {
            logger.debug("Applying client plugin", metadata: [LoggingKeys.pluginName: "\(plugin.name)"])
            plugin.configureClient(&self)
        }
        self.plugins = plugins
    }
}
