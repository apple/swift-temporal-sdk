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
    ///
    /// - Note: This method is intended to be called exactly once per configuration value. Calling
    ///   it again would re-run each plugin against the already-mutated configuration and duplicate
    ///   any appended state such as interceptors.
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
    /// to this configuration in order, then appends plugin-contributed workflows to
    /// ``WorkflowReplayer/Configuration/workflows``.
    ///
    /// Each plugin's ``WorkerPlugin/configureReplayer(_:)`` runs against the same configuration
    /// value, in the order they appear. The plugin list is captured before the first plugin runs,
    /// so a plugin that mutates ``WorkflowReplayer/Configuration/plugins`` during its own
    /// `configureReplayer(_:)` does not affect the sequence applied in this call or the set of
    /// workflows folded in afterward. Emits one `debug` entry per applied plugin on
    /// ``WorkflowReplayer/Configuration/logger``, tagged with the plugin's ``WorkerPlugin/name``;
    /// the client and worker variants take `logger:` as a parameter because their configurations
    /// don't expose one.
    ///
    /// Called automatically by ``WorkflowReplayer/init(configuration:)``.
    ///
    /// - Note: This method is intended to be called exactly once per configuration value. Calling
    ///   it again would re-run each plugin against the already-mutated configuration and duplicate
    ///   any appended state such as interceptors and workflows.
    package mutating func applyPlugins() {
        let plugins = self.plugins
        for plugin in plugins {
            self.logger.debug("Applying replayer plugin", metadata: [LoggingKeys.pluginName: "\(plugin.name)"])
            plugin.configureReplayer(&self)
        }
        self.workflows += plugins.flatMap(\.workflows)
    }
}
