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

extension TemporalWorker.Configuration {
    /// Applies ``TemporalWorker/Configuration/plugins`` to this configuration, in order.
    ///
    /// Each plugin's ``WorkerPlugin/configureWorker(_:)`` sees the changes made by the plugins
    /// before it. The plugin list is captured before the first plugin runs and restored afterward,
    /// so a plugin that changes ``TemporalWorker/Configuration/plugins`` has no effect.
    ///
    /// Called by ``TemporalWorker/init(configuration:transport:activityContainers:activities:workflows:logger:)``.
    ///
    /// - Parameter logger: Receives one `debug` entry per plugin, tagged with its
    ///   ``TemporalPlugin/name``.
    ///
    /// - Note: Call this once per configuration value. Calling it again re-runs every plugin and
    ///   duplicates anything they append, such as interceptors.
    package mutating func applyPlugins(logger: Logger) {
        let plugins = self.plugins
        for plugin in plugins {
            logger.debug("Applying worker plugin", metadata: [LoggingKeys.pluginName: "\(plugin.name)"])
            plugin.configureWorker(&self)
        }
        self.plugins = plugins
    }
}
