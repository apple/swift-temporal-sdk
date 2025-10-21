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
import Temporal
import Testing

@Suite
struct WorkerConfigurationTests {
    @Test
    func containerReaderInit() async throws {
        let namespace = "testdefault"
        let taskQueue = "testtaskqueue"
        let buildId = "testbuildid"
        let clientServerHostname = "testserverhostname.com"
        let clientIdentity = "testclientidentity"

        let container = ConfigReader(
            provider: InMemoryProvider(
                values: [
                    // include `temporal` prefix
                    ["temporal", "worker", "namespace"]: .init(stringLiteral: namespace),
                    ["temporal", "worker", "taskqueue"]: .init(stringLiteral: taskQueue),
                    ["temporal", "worker", "buildid"]: .init(stringLiteral: buildId),
                    ["temporal", "worker", "client", "instrumentation", "serverhostname"]: .init(stringLiteral: clientServerHostname),
                    ["temporal", "worker", "client", "identity"]: .init(stringLiteral: clientIdentity),
                ]
            )
        )

        let config = try TemporalWorker.Configuration(
            configReader:
                container
                .scoped(to: "temporal")  // scope container to `temporal` prefix
        )

        #expect(config.namespace == namespace)
        #expect(config.taskQueue == taskQueue)
        #expect(config.clientIdentity == clientIdentity)
        #expect(config.instrumentation.serverHostname == clientServerHostname)
        #expect(config.interceptors.count == 1)  // default tracing interceptor
        guard case .none(let noneParameters) = config.versioningStrategy.kind else {
            Issue.record("Expected `.none` versioning strategy, got: \(config.versioningStrategy)")
            return
        }
        #expect(noneParameters.buildId == buildId)

        // sadly the thrown error is `package`-level
        #expect(throws: (any Error).self, "If no scoping for container is provided, config creation should throw an error") {
            _ = try TemporalWorker.Configuration(
                configReader: container  // no scoping
            )
        }
    }
}
