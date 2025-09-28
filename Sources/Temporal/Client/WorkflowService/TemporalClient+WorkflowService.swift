//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Temporal SDK open source project
//
// Copyright (c) 2025 Apple Inc. and the Swift Temporal SDK project authors
// Licensed under MIT License
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Swift Cassandra Client project authors
//
// SPDX-License-Identifier: MIT
//
//===----------------------------------------------------------------------===//

import GRPCCore

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

extension TemporalClient {
    /// Provides access to Temporal workflow services for workflow lifecycle management.
    public struct WorkflowService: Sendable {
        /// The configuration of the ``TemporalClient``.
        package let configuration: TemporalClient.Configuration
        let client: TemporalClient.ConfiguredClient
        let metadata: GRPCCore.Metadata

        /// Initializes a new Temporal workflow client for accessing workflow services.
        ///
        /// - Parameters:
        ///   - client: A type-erased, configured `GRPCClient` used for performing RPCs to the Temporal server.
        ///   - configuration: The configuration of the Temporal client including namespace, identity, and data conversion settings.
        ///   - metadata: Metadata set on the client for request context, authentication, and tracing.
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
