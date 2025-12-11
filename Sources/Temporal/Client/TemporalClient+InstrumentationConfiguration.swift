//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Temporal SDK open source project
//
// Copyright (c) 2025 Apple Inc. and the Swift Temporal SDK project authors
// Licensed under MIT License
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Swift Temporal SDK project authors
//
// SPDX-License-Identifier: MIT
//
//===----------------------------------------------------------------------===//

public import Configuration

extension TemporalClient.Configuration {
    /// Configuration settings that control instrumentation features including tracing and observability.
    public struct Instrumentation: Hashable, Sendable {
        /// The Temporal server’s hostname for instrumentation purposes.
        ///
        /// This hostname is used by observability tools to identify the target server in distributed tracing
        /// and metrics systems. It populates the `server.address` attribute on tracing spans, enabling
        /// proper correlation between client operations and server-side processing.
        public var serverHostname: String

        /// Creates a new client instrumentation configuration with the specified settings.
        ///
        /// - Parameters:
        ///   - serverHostname: The hostname of the Temporal server for instrumentation purposes.
        public init(serverHostname: String) {
            self.serverHostname = serverHostname
        }

        /// Creates an instrumentation configuration from external configuration data.
        ///
        /// This initializer reads the server hostname from a `ConfigReader`, typically loaded from
        /// environment variables or configuration files.
        ///
        /// ## Required configuration keys
        ///
        /// - `client.instrumentation.serverhostname`: The Temporal server
        /// hostname for telemetry identification
        ///
        /// - Parameters:
        ///   - configReader: The configuration reader containing the required hostname value.
        /// - Throws: Configuration errors if the required hostname key is missing or invalid.
        public init(configReader: ConfigReader) throws {
            let snapshot = configReader.snapshot()
            let serverHostname = try snapshot.requiredString(forKey: .clientServerHostname)

            self.init(serverHostname: serverHostname)
        }
    }
}
