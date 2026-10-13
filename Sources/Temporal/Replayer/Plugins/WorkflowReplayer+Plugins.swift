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

import Logging

extension WorkflowReplayer.Configuration {
    /// Runs each plugin's ``WorkerPlugin/configureReplayer(_:)`` in order, appends their
    /// ``WorkerPlugin/workflows``, then restores `plugins`, so a plugin that edits the list
    /// has no effect.
    package mutating func applyPlugins() {
        let plugins = self.plugins
        let logger = Logger.current
        for plugin in plugins {
            logger.debug("Applying replayer plugin", metadata: [LoggingKeys.pluginName: "\(plugin.name)"])
            plugin.configureReplayer(&self)
        }
        self.workflows += plugins.flatMap(\.workflows)
        self.plugins = plugins
    }
}
