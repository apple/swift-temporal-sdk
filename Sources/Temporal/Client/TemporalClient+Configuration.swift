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

import Configuration

extension TemporalClient {
    /// Configuration settings that define how the client connects to and interacts with the Temporal server.
    public struct Configuration: Sendable {
        /// The instrumentation configuration that controls tracing and observability features.
        ///
        /// Contains settings for distributed tracing, metrics collection, and server hostname identification
        /// used by observability tools to track client operations across the system.
        public var instrumentation: Instrumentation

        /// The Temporal namespace that scopes workflow and activity executions.
        ///
        /// Namespaces provide isolation between different environments or tenants within a Temporal cluster.
        /// All workflows and activities executed by this client will run within the specified namespace.
        public var namespace: String

        /// A human-readable identifier that distinguishes this client process in logs and monitoring.
        ///
        /// This identity appears in server logs and monitoring tools to help identify which client instance
        /// performed specific operations. It defaults to a combination of the SDK name and version but can
        /// be customized to include process IDs, hostnames, or other identifying information.
        public var identity: String

        /// The data converter that handles serialization and deserialization of workflow inputs and outputs.
        ///
        /// Controls how workflow inputs, outputs, and other data are converted between Swift types and the
        /// format used for network transmission and storage.
        public var dataConverter: DataConverter

        /// The interceptors that process client requests in the order they are applied.
        ///
        /// Interceptors provide a way to customize or augment client behavior by intercepting requests
        /// before they are sent to the server. Common use cases include logging, metrics collection,
        /// authentication, and request modification. Interceptors are applied in the order they appear in this array.
        public var interceptors: [any ClientInterceptor]

        /// Optional API key for authenticating with Temporal Cloud.
        ///
        /// When provided, the API key is sent as a Bearer token in the `authorization` header with all
        /// requests to the Temporal server. This provides an alternative to mTLS certificate authentication
        /// for Temporal Cloud deployments.
        ///
        /// If both an API key and mTLS certificates are configured, the API key takes precedence for
        /// authentication while mTLS is still used for transport encryption.
        public var apiKey: String?

        /// The SDK name identifier sent in all RPC calls to identify the client implementation.
        ///
        /// This constant value identifies this SDK implementation to the Temporal server and appears in
        /// server logs for debugging and monitoring purposes. It is automatically included as the
        /// `client-name` header in all RPC calls.
        let clientName: String = "swift-temporal"

        /// The SDK version identifier that allows the server to validate client compatibility.
        ///
        /// This version string is derived from the current Git tag or commit and helps the Temporal server
        /// determine client compatibility and feature support. It is automatically included as the
        /// `client-version` header in all RPC calls, and the server uses this information to decide
        /// whether the client version is supported.
        let clientVersion: String = Constants.sdkVersion  // derived from current git tag / commit

        /// Creates a new client configuration with the specified settings.
        ///
        /// This initializer creates a configuration with explicit parameter values. All parameters have
        /// sensible defaults except for the instrumentation configuration, which must be provided since
        /// it contains server-specific connection details.
        ///
        /// ## Default Tracing
        ///
        /// By default, the ``TemporalClientTracingInterceptor`` is included in the interceptors list to
        /// provide distributed tracing capabilities. To disable tracing, pass an empty array or a custom
        /// list of interceptors that doesn't include the tracing interceptor.
        ///
        /// ## Identity Generation
        ///
        /// If no identity is provided, one is automatically generated using the format `swift-temporal-<version>`
        /// where `<version>` is the current SDK version. This ensures each client instance has a unique
        /// identifier for logging and monitoring purposes.
        ///
        /// - Parameters:
        ///   - instrumentation: Configuration that controls tracing and observability features.
        ///   - namespace: The Temporal namespace that scopes workflow and activity executions. Defaults to "default".
        ///   - identity: A human-readable identifier for this client process. If `nil`, an identity is generated from the SDK name and version.
        ///   - apiKey: Optional API key for Temporal Cloud authentication. When provided, it is sent as a Bearer token in the authorization header.
        ///   - dataConverter: The converter that handles serialization of workflow data. Defaults to the standard JSON converter.
        ///   - interceptors: Request processing interceptors applied in the specified order. Defaults to the tracing interceptor.
        public init(
            instrumentation: Instrumentation,
            namespace: String = "default",
            identity: String? = nil,
            apiKey: String? = nil,
            dataConverter: DataConverter = DataConverter.default,
            interceptors: [any ClientInterceptor] = [TemporalClientTracingInterceptor()]
        ) {
            self.instrumentation = instrumentation
            self.namespace = namespace
            self.identity = identity ?? "\(self.clientName)-\(self.clientVersion)"
            self.apiKey = apiKey
            self.dataConverter = dataConverter
            self.interceptors = interceptors
        }

        /// Creates a Temporal client configuration from external configuration data.
        ///
        /// This initializer reads configuration values from a `ConfigReader`, typically loaded from
        /// environment variables or configuration files. The tracing interceptor is enabled by default -
        /// override the `interceptors` parameter to customize this behavior.
        ///
        /// ## Required configuration keys
        ///
        /// The following keys must be present in the configuration:
        /// - `client.instrumentation.serverhostname`: The Temporal server
        /// hostname for instrumentation
        ///
        /// ## Optional configuration keys
        ///
        /// - `client.namespace`: The Temporal namespace where this worker polls for tasks
        /// - `client.identity`: A human-readable worker client identifier (defaults to
        /// SDK name and version)
        ///
        /// - Parameters:
        ///   - configReader: The configuration reader containing the required configuration values.
        ///   - dataConverter: The converter for encoding and decoding payloads. Defaults to the
        ///   standard converter.
        ///   - interceptors: A collection of client interceptors. Defaults to tracing interceptor only.
        /// - Throws: Configuration errors if required keys are missing or invalid.
        public init(
            configReader: ConfigReader,
            dataConverter: DataConverter = DataConverter.default,
            interceptors: [any ClientInterceptor] = [TemporalClientTracingInterceptor()]
        ) throws {
            let (namespace, identity) = configReader.withSnapshot { snapshotReader in
                (
                    snapshotReader.string(forKey: .clientNamespace, default: "default"),
                    snapshotReader.string(forKey: .clientIdentity)  // defaults to `nil`
                )
            }

            try self.init(
                instrumentation: .init(configReader: configReader),
                namespace: namespace,
                identity: identity,
                dataConverter: dataConverter,
                interceptors: interceptors
            )
        }
    }
}
