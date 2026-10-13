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

internal import Logging

extension WorkflowReplayer.Configuration {
    /// Applies ``WorkflowReplayer/Configuration/plugins`` to this configuration, in order.
    ///
    /// Each plugin's ``WorkerPlugin/configureReplayer(_:)`` sees the changes made by the plugins
    /// before it. The plugin list is captured before the first plugin runs and restored afterward,
    /// so a plugin that changes ``WorkflowReplayer/Configuration/plugins`` has no effect. One
    /// `debug` entry per plugin goes to ``WorkflowReplayer/Configuration/logger``.
    ///
    /// Called by ``WorkflowReplayer/init(configuration:)``.
    ///
    /// - Note: Call this once per configuration value. Calling it again re-runs every plugin and
    ///   duplicates anything they append, such as interceptors.
    package mutating func applyPlugins() {
        let plugins = self.plugins
        // Read once, so every entry goes through the same logger even if a plugin replaces it.
        let logger = self.logger
        for plugin in plugins {
            logger.debug("Applying replayer plugin", metadata: [LoggingKeys.pluginName: "\(plugin.name)"])
            plugin.configureReplayer(&self)
        }
        self.plugins = plugins
    }
}
