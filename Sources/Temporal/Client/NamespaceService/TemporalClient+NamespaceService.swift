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

import GRPCCore

extension TemporalClient {
    /// Provides access to Temporal namespace management operations.
    public struct NamespaceService: Sendable {
        /// The configuration of the parent Temporal client.
        package let configuration: TemporalClient.Configuration

        /// The underlying configured client used for gRPC communication.
        let client: TemporalClient.ConfiguredClient

        /// Metadata applied to all namespace service requests.
        let metadata: GRPCCore.Metadata

        /// Initializes a new Temporal namespace service client.
        ///
        /// - Parameters:
        ///   - client: A configured gRPC client for performing namespace operations.
        ///   - configuration: The parent Temporal client configuration.
        ///   - metadata: Request metadata including authentication and tracing headers.
        init(
            client: TemporalClient.ConfiguredClient,
            configuration: TemporalClient.Configuration,
            metadata: GRPCCore.Metadata
        ) {
            self.client = client
            self.configuration = configuration
            self.metadata = metadata
        }
    }
}
