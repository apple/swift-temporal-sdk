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

extension TemporalWorker.Configuration {
    /// Applies the plugins set on ``TemporalWorker/Configuration/plugins`` to this configuration in order.
    ///
    /// Each plugin's ``WorkerPlugin/configure(_:)`` runs against the same configuration value, in
    /// the order they appear. The plugin list is captured before the first plugin runs, so
    /// callers can safely use the returned snapshot to fold in plugin-contributed activities and
    /// workflows even if a plugin mutates ``TemporalWorker/Configuration/plugins`` during its own
    /// `configure(_:)`.
    ///
    /// Called automatically by ``TemporalWorker/init(configuration:transport:activityContainers:activities:workflows:logger:)``.
    ///
    /// - Parameter logger: The logger used to emit one `debug` entry per applied plugin, tagged
    ///   with the plugin's ``WorkerPlugin/name``.
    /// - Returns: The plugin list captured before applying, suitable for folding contributed
    ///   activities and workflows into the worker registration.
    @discardableResult
    package mutating func applyPlugins(logger: Logger) -> [any WorkerPlugin] {
        let plugins = self.plugins
        for plugin in plugins {
            logger.debug("Applying worker plugin", metadata: [LoggingKeys.pluginName: "\(plugin.name)"])
            plugin.configure(&self)
        }
        return plugins
    }
}

extension WorkflowReplayer.Configuration {
    /// Applies the replayer side of the plugins set on ``WorkflowReplayer/Configuration/plugins``
    /// to this configuration in order.
    ///
    /// Each plugin's ``WorkerPlugin/configureReplayer(_:)`` runs against the same configuration
    /// value, in the order they appear. The plugin list is captured before the first plugin runs,
    /// so callers can safely use the returned snapshot to fold in plugin-contributed workflows.
    /// Emits one `debug` entry per applied plugin on ``WorkflowReplayer/Configuration/logger``,
    /// tagged with the plugin's ``WorkerPlugin/name``.
    ///
    /// Called automatically by ``WorkflowReplayer/init(configuration:)``.
    ///
    /// - Returns: The plugin list captured before applying, suitable for folding contributed
    ///   workflows into the replayer registration.
    @discardableResult
    package mutating func applyPlugins() -> [any WorkerPlugin] {
        let plugins = self.plugins
        for plugin in plugins {
            self.logger.debug("Applying replayer plugin", metadata: [LoggingKeys.pluginName: "\(plugin.name)"])
            plugin.configureReplayer(&self)
        }
        return plugins
    }
}
