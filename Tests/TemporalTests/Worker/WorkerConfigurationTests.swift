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

    @Test
    func workerHeartbeatIntervalDefaultsToZero() async throws {
        let config = TemporalWorker.Configuration(
            namespace: "test",
            taskQueue: "test-queue",
            instrumentation: .init(serverHostname: "localhost")
        )

        #expect(config.workerHeartbeatInterval == .zero)
    }

    @Test
    func workerHeartbeatIntervalCanBeSet() async throws {
        var config = TemporalWorker.Configuration(
            namespace: "test",
            taskQueue: "test-queue",
            instrumentation: .init(serverHostname: "localhost")
        )

        config.workerHeartbeatInterval = .seconds(30)
        #expect(config.workerHeartbeatInterval == .seconds(30))

        config.workerHeartbeatInterval = .milliseconds(500)
        #expect(config.workerHeartbeatInterval == .milliseconds(500))

        config.workerHeartbeatInterval = .zero
        #expect(config.workerHeartbeatInterval == .zero)
    }

    @Test
    func workerHeartbeatIntervalFromConfigReader() async throws {
        let namespace = "testdefault"
        let taskQueue = "testtaskqueue"
        let buildId = "testbuildid"
        let clientServerHostname = "testserverhostname.com"
        let clientIdentity = "testclientidentity"
        let heartbeatIntervalMs = 5000

        let container = ConfigReader(
            provider: InMemoryProvider(
                values: [
                    ["temporal", "worker", "namespace"]: .init(stringLiteral: namespace),
                    ["temporal", "worker", "taskqueue"]: .init(stringLiteral: taskQueue),
                    ["temporal", "worker", "buildid"]: .init(stringLiteral: buildId),
                    ["temporal", "worker", "client", "instrumentation", "serverhostname"]: .init(stringLiteral: clientServerHostname),
                    ["temporal", "worker", "client", "identity"]: .init(stringLiteral: clientIdentity),
                    ["temporal", "worker", "heartbeatintervalms"]: .init(integerLiteral: heartbeatIntervalMs),
                ]
            )
        )

        let config = try TemporalWorker.Configuration(
            configReader: container.scoped(to: "temporal")
        )

        #expect(config.workerHeartbeatInterval == .milliseconds(heartbeatIntervalMs))
    }

    // MARK: - Worker Tuner

    @Test
    func tunerDefaultsToFixedSize() {
        let config = TemporalWorker.Configuration(
            namespace: "test",
            taskQueue: "test-queue",
            instrumentation: .init(serverHostname: "localhost")
        )

        guard case .fixedSize(let wfSupplier) = config.tuner.workflowSlotSupplier.kind else {
            Issue.record("Expected fixedSize workflow slot supplier")
            return
        }
        #expect(wfSupplier.maximumSlots == 100)

        guard case .fixedSize(let actSupplier) = config.tuner.activitySlotSupplier.kind else {
            Issue.record("Expected fixedSize activity slot supplier")
            return
        }
        #expect(actSupplier.maximumSlots == 100)

        guard case .fixedSize(let laSupplier) = config.tuner.localActivitySlotSupplier.kind else {
            Issue.record("Expected fixedSize local activity slot supplier")
            return
        }
        #expect(laSupplier.maximumSlots == 100)
    }

    @Test
    func tunerCanBeSetWithFixedSizeSuppliers() {
        var config = TemporalWorker.Configuration(
            namespace: "test",
            taskQueue: "test-queue",
            instrumentation: .init(serverHostname: "localhost")
        )

        config.tuner = WorkerTuner(
            workflowSlotSupplier: .fixedSize(.init(maximumSlots: 50)),
            activitySlotSupplier: .fixedSize(.init(maximumSlots: 200)),
            localActivitySlotSupplier: .fixedSize(.init(maximumSlots: 75))
        )

        let tuner = config.tuner

        guard case .fixedSize(let wfSupplier) = tuner.workflowSlotSupplier.kind else {
            Issue.record("Expected fixedSize workflow slot supplier")
            return
        }
        #expect(wfSupplier.maximumSlots == 50)

        guard case .fixedSize(let actSupplier) = tuner.activitySlotSupplier.kind else {
            Issue.record("Expected fixedSize activity slot supplier")
            return
        }
        #expect(actSupplier.maximumSlots == 200)

        guard case .fixedSize(let laSupplier) = tuner.localActivitySlotSupplier.kind else {
            Issue.record("Expected fixedSize local activity slot supplier")
            return
        }
        #expect(laSupplier.maximumSlots == 75)
    }

    @Test
    func tunerCanBeSetWithResourceBasedSuppliers() {
        var config = TemporalWorker.Configuration(
            namespace: "test",
            taskQueue: "test-queue",
            instrumentation: .init(serverHostname: "localhost")
        )

        let options = ResourceBasedSlotSupplierOptions(
            minimumSlots: 10,
            maximumSlots: 500,
            rampThrottle: .milliseconds(100)
        )
        let tunerOptions = ResourceBasedTunerOptions(
            targetMemoryUsage: 0.8,
            targetCpuUsage: 0.9
        )

        config.tuner = WorkerTuner(
            workflowSlotSupplier: .resourceBased(options, tunerOptions: tunerOptions),
            activitySlotSupplier: .resourceBased(options, tunerOptions: tunerOptions),
            localActivitySlotSupplier: .resourceBased(options, tunerOptions: tunerOptions)
        )

        let tuner = config.tuner

        guard case .resourceBased(let wfOptions, _) = tuner.workflowSlotSupplier.kind else {
            Issue.record("Expected resourceBased workflow slot supplier")
            return
        }
        #expect(wfOptions.minimumSlots == 10)
        #expect(wfOptions.maximumSlots == 500)
        #expect(wfOptions.rampThrottle == .milliseconds(100))
    }

    @Test
    func resourceBasedTunerFactoryMethod() {
        let tuner = WorkerTuner.resourceBased(
            targetMemoryUsage: 0.75,
            targetCpuUsage: 0.85
        )

        guard case .resourceBased = tuner.workflowSlotSupplier.kind else {
            Issue.record("Expected resourceBased workflow slot supplier")
            return
        }

        guard case .resourceBased = tuner.activitySlotSupplier.kind else {
            Issue.record("Expected resourceBased activity slot supplier")
            return
        }

        guard case .resourceBased(_, let laTunerOptions) = tuner.localActivitySlotSupplier.kind else {
            Issue.record("Expected resourceBased local activity slot supplier")
            return
        }

        #expect(laTunerOptions.targetMemoryUsage == 0.75)
        #expect(laTunerOptions.targetCpuUsage == 0.85)
    }

    @Test
    func resourceBasedSlotSupplierOptionsDefaults() {
        let options = ResourceBasedSlotSupplierOptions()

        #expect(options.minimumSlots == 5)
        #expect(options.maximumSlots == 100)
        #expect(options.rampThrottle == .milliseconds(50))
    }

    @Test
    func fixedSizeSlotSupplierDefaults() {
        let options = FixedSizeSlotSupplierOptions()

        #expect(options.maximumSlots == 100)
    }

    @Test
    func workerTunerDefaults() {
        let tuner = WorkerTuner()

        guard case .fixedSize(let wfSupplier) = tuner.workflowSlotSupplier.kind else {
            Issue.record("Expected fixedSize workflow slot supplier")
            return
        }
        #expect(wfSupplier.maximumSlots == 100)

        guard case .fixedSize(let actSupplier) = tuner.activitySlotSupplier.kind else {
            Issue.record("Expected fixedSize activity slot supplier")
            return
        }
        #expect(actSupplier.maximumSlots == 100)

        guard case .fixedSize(let laSupplier) = tuner.localActivitySlotSupplier.kind else {
            Issue.record("Expected fixedSize local activity slot supplier")
            return
        }
        #expect(laSupplier.maximumSlots == 100)
    }

    @Test
    func tunerWithMixedSuppliers() {
        var config = TemporalWorker.Configuration(
            namespace: "test",
            taskQueue: "test-queue",
            instrumentation: .init(serverHostname: "localhost")
        )

        let tunerOptions = ResourceBasedTunerOptions()

        config.tuner = WorkerTuner(
            workflowSlotSupplier: .fixedSize(.init(maximumSlots: 50)),
            activitySlotSupplier: .resourceBased(.init(), tunerOptions: tunerOptions),
            localActivitySlotSupplier: .fixedSize(.init(maximumSlots: 100))
        )

        let tuner = config.tuner

        guard case .fixedSize(let wfSupplier) = tuner.workflowSlotSupplier.kind else {
            Issue.record("Expected fixedSize workflow slot supplier")
            return
        }
        #expect(wfSupplier.maximumSlots == 50)

        guard case .resourceBased(_, let actTunerOptions) = tuner.activitySlotSupplier.kind else {
            Issue.record("Expected resourceBased activity slot supplier")
            return
        }
        #expect(actTunerOptions.targetMemoryUsage == 0.8)

        guard case .fixedSize(let laSupplier) = tuner.localActivitySlotSupplier.kind else {
            Issue.record("Expected fixedSize local activity slot supplier")
            return
        }
        #expect(laSupplier.maximumSlots == 100)
    }

    // MARK: - Tuner from ConfigReader

    @Test
    func tunerFromConfigReaderFixedSize() async throws {
        let container = ConfigReader(
            provider: InMemoryProvider(
                values: [
                    ["temporal", "worker", "namespace"]: .init(stringLiteral: "test"),
                    ["temporal", "worker", "taskqueue"]: .init(stringLiteral: "test-queue"),
                    ["temporal", "worker", "buildid"]: .init(stringLiteral: "build-1"),
                    ["temporal", "worker", "client", "instrumentation", "serverhostname"]: .init(
                        stringLiteral: "localhost"
                    ),
                    ["temporal", "worker", "client", "identity"]: .init(stringLiteral: "test-identity"),
                    ["temporal", "worker", "tuner", "workflow", "type"]: .init(stringLiteral: "fixed"),
                    ["temporal", "worker", "tuner", "workflow", "maxslots"]: .init(integerLiteral: 50),
                    ["temporal", "worker", "tuner", "activity", "type"]: .init(stringLiteral: "fixed"),
                    ["temporal", "worker", "tuner", "activity", "maxslots"]: .init(integerLiteral: 200),
                    ["temporal", "worker", "tuner", "localactivity", "type"]: .init(stringLiteral: "fixed"),
                    ["temporal", "worker", "tuner", "localactivity", "maxslots"]: .init(integerLiteral: 75),
                ]
            )
        )

        let config = try TemporalWorker.Configuration(
            configReader: container.scoped(to: "temporal")
        )

        let tuner = config.tuner

        guard case .fixedSize(let wfSupplier) = tuner.workflowSlotSupplier.kind else {
            Issue.record("Expected fixedSize workflow slot supplier")
            return
        }
        #expect(wfSupplier.maximumSlots == 50)

        guard case .fixedSize(let actSupplier) = tuner.activitySlotSupplier.kind else {
            Issue.record("Expected fixedSize activity slot supplier")
            return
        }
        #expect(actSupplier.maximumSlots == 200)

        guard case .fixedSize(let laSupplier) = tuner.localActivitySlotSupplier.kind else {
            Issue.record("Expected fixedSize local activity slot supplier")
            return
        }
        #expect(laSupplier.maximumSlots == 75)
    }

    @Test
    func tunerFromConfigReaderResourceBased() async throws {
        let container = ConfigReader(
            provider: InMemoryProvider(
                values: [
                    ["temporal", "worker", "namespace"]: .init(stringLiteral: "test"),
                    ["temporal", "worker", "taskqueue"]: .init(stringLiteral: "test-queue"),
                    ["temporal", "worker", "buildid"]: .init(stringLiteral: "build-1"),
                    ["temporal", "worker", "client", "instrumentation", "serverhostname"]: .init(
                        stringLiteral: "localhost"
                    ),
                    ["temporal", "worker", "client", "identity"]: .init(stringLiteral: "test-identity"),
                    ["temporal", "worker", "tuner", "workflow", "type"]: .init(stringLiteral: "resource-based"),
                    ["temporal", "worker", "tuner", "activity", "type"]: .init(stringLiteral: "resource-based"),
                    ["temporal", "worker", "tuner", "localactivity", "type"]: .init(stringLiteral: "resource-based"),
                    ["temporal", "worker", "tuner", "targetmemoryusage"]: .init(floatLiteral: 0.75),
                    ["temporal", "worker", "tuner", "targetcpuusage"]: .init(floatLiteral: 0.85),
                ]
            )
        )

        let config = try TemporalWorker.Configuration(
            configReader: container.scoped(to: "temporal")
        )

        let tuner = config.tuner

        guard case .resourceBased = tuner.workflowSlotSupplier.kind else {
            Issue.record("Expected resourceBased workflow slot supplier")
            return
        }

        guard case .resourceBased = tuner.activitySlotSupplier.kind else {
            Issue.record("Expected resourceBased activity slot supplier")
            return
        }

        guard case .resourceBased = tuner.localActivitySlotSupplier.kind else {
            Issue.record("Expected resourceBased local activity slot supplier")
            return
        }

        if case .resourceBased(_, let tunerOptions) = tuner.workflowSlotSupplier.kind {
            #expect(tunerOptions.targetMemoryUsage == 0.75)
            #expect(tunerOptions.targetCpuUsage == 0.85)
        } else {
            Issue.record("Expected resource-based supplier")
        }
    }

    @Test
    func tunerFromConfigReaderNoTunerKeysDefaultsToFixedSize() async throws {
        let container = ConfigReader(
            provider: InMemoryProvider(
                values: [
                    ["temporal", "worker", "namespace"]: .init(stringLiteral: "test"),
                    ["temporal", "worker", "taskqueue"]: .init(stringLiteral: "test-queue"),
                    ["temporal", "worker", "buildid"]: .init(stringLiteral: "build-1"),
                    ["temporal", "worker", "client", "instrumentation", "serverhostname"]: .init(
                        stringLiteral: "localhost"
                    ),
                    ["temporal", "worker", "client", "identity"]: .init(stringLiteral: "test-identity"),
                ]
            )
        )

        let config = try TemporalWorker.Configuration(
            configReader: container.scoped(to: "temporal")
        )

        // Default tuner should be fixed-size with 100 slots for all task types
        let tuner = config.tuner

        guard case .fixedSize(let wfSupplier) = tuner.workflowSlotSupplier.kind else {
            Issue.record("Expected fixedSize workflow slot supplier")
            return
        }
        #expect(wfSupplier.maximumSlots == 100)

        guard case .fixedSize(let actSupplier) = tuner.activitySlotSupplier.kind else {
            Issue.record("Expected fixedSize activity slot supplier")
            return
        }
        #expect(actSupplier.maximumSlots == 100)

        guard case .fixedSize(let laSupplier) = tuner.localActivitySlotSupplier.kind else {
            Issue.record("Expected fixedSize local activity slot supplier")
            return
        }
        #expect(laSupplier.maximumSlots == 100)
    }

    @Test
    func tunerFromConfigReaderMixed() async throws {
        let container = ConfigReader(
            provider: InMemoryProvider(
                values: [
                    ["temporal", "worker", "namespace"]: .init(stringLiteral: "test"),
                    ["temporal", "worker", "taskqueue"]: .init(stringLiteral: "test-queue"),
                    ["temporal", "worker", "buildid"]: .init(stringLiteral: "build-1"),
                    ["temporal", "worker", "client", "instrumentation", "serverhostname"]: .init(
                        stringLiteral: "localhost"
                    ),
                    ["temporal", "worker", "client", "identity"]: .init(stringLiteral: "test-identity"),
                    ["temporal", "worker", "tuner", "workflow", "type"]: .init(stringLiteral: "fixed"),
                    ["temporal", "worker", "tuner", "workflow", "maxslots"]: .init(integerLiteral: 50),
                    ["temporal", "worker", "tuner", "activity", "type"]: .init(stringLiteral: "resource-based"),
                    ["temporal", "worker", "tuner", "targetmemoryusage"]: .init(floatLiteral: 0.7),
                    ["temporal", "worker", "tuner", "targetcpuusage"]: .init(floatLiteral: 0.8),
                ]
            )
        )

        let config = try TemporalWorker.Configuration(
            configReader: container.scoped(to: "temporal")
        )

        let tuner = config.tuner

        guard case .fixedSize(let wfSupplier) = tuner.workflowSlotSupplier.kind else {
            Issue.record("Expected fixedSize workflow slot supplier")
            return
        }
        #expect(wfSupplier.maximumSlots == 50)

        guard case .resourceBased(_, let actTunerOptions) = tuner.activitySlotSupplier.kind else {
            Issue.record("Expected resourceBased activity slot supplier")
            return
        }
        #expect(actTunerOptions.targetMemoryUsage == 0.7)
        #expect(actTunerOptions.targetCpuUsage == 0.8)

        // localactivity type not set, defaults to fixed with default slots
        guard case .fixedSize(let laSupplier) = tuner.localActivitySlotSupplier.kind else {
            Issue.record("Expected fixedSize local activity slot supplier (default)")
            return
        }
        #expect(laSupplier.maximumSlots == 100)
    }
}
