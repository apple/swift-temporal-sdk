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

import Configuration
import Temporal
import Testing

@Suite(.tags(.clientTests))
struct ClientConfigurationTests {
    @Test
    func containerReaderInit() async throws {
        let serverHostname = "testserverhostname.com"
        let namespace = "testdefault"
        let identity = "testidentity"

        let container = ConfigReader(
            provider: InMemoryProvider(
                values: [
                    // include `temporal` prefix
                    ["temporal", "client", "instrumentation", "serverhostname"]: .init(stringLiteral: serverHostname),
                    ["temporal", "client", "namespace"]: .init(stringLiteral: namespace),
                    ["temporal", "client", "identity"]: .init(stringLiteral: identity),
                ]
            )
        )

        let config = try TemporalClient.Configuration(
            configReader: container.scoped(to: "temporal")  // scope container to `temporal` prefix
        )

        #expect(config.instrumentation.serverHostname == serverHostname)
        #expect(config.namespace == namespace)
        #expect(config.identity == identity)
        #expect(config.interceptors.count == 1)  // default tracing interceptor

        // sadly the thrown error is `package`-level
        #expect(throws: Error.self, "If no scoping for container is provided, config creation should throw an error") {
            _ = try TemporalClient.Configuration(
                configReader: container  // no scoping
            )
        }
    }
}
