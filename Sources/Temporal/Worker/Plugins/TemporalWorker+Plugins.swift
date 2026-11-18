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

extension TemporalWorker.Configuration {
    /// Runs each plugin's ``WorkerPlugin/configureWorker(_:)`` in order, then restores `plugins`,
    /// so a plugin that edits the list has no effect.
    package mutating func applyPlugins() {
        let plugins = self.plugins
        let logger = Logger.current
        for plugin in plugins {
            logger.debug("Applying worker plugin", metadata: [LoggingKeys.pluginName: "\(plugin.name)"])
            plugin.configureWorker(&self)
        }
        self.plugins = plugins
    }
}

/// Wraps `body` in each plugin's ``WorkerPlugin/runWorker(configuration:next:)``.
package nonisolated(nonsending) func applyWorkerRunChain(
    plugins: ArraySlice<any WorkerPlugin>,
    configuration: TemporalWorker.Configuration,
    body: nonisolated(nonsending) () async throws -> Void
) async throws {
    guard let plugin = plugins.first else {
        try await body()
        return
    }
    try await plugin.runWorker(configuration: configuration) {
        try await applyWorkerRunChain(
            plugins: plugins.dropFirst(),
            configuration: configuration,
            body: body
        )
    }
}
