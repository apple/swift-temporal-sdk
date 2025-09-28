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
    /// Intercepted service for managing workflow and schedule lifecycle.
    ///
    /// Requests are routed through the configured ``TemporalClient/Configuration-swift.struct/interceptors``.
    package struct InterceptedService: Sendable {
        /// The Temporal interceptor used for all workflow and schedule operations.
        package let interceptor: TemporalClient.Interceptor

        /// Creates a new intercepted service for workflow and schedule operations.
        ///
        /// - Note: In contrast to ``TemporalClient/WorkflowService-swift.struct``, this intercepted service routes the requests
        /// through the configured ``TemporalClient/Configuration-swift.struct/interceptors`` on the ``TemporalClient``.
        ///
        /// - Parameters:
        ///   - interceptor: The Temporal interceptor used for all workflow and schedule operations.
        package init(interceptor: TemporalClient.Interceptor) {
            self.interceptor = interceptor
        }
    }
}
