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

private import Logging
import SwiftProtobuf
import Synchronization
import Temporal
import Testing

private let testLogger = Logger(label: "test")

private struct MarkerPayloadCodec: PayloadCodec {
    func encode(payloads: some Collection<Api.Common.V1.Payload>) async throws -> [Api.Common.V1.Payload] {
        Array(payloads)
    }
    func decode(payloads: some Collection<Api.Common.V1.Payload>) async throws -> [Api.Common.V1.Payload] {
        Array(payloads)
    }
}

@Workflow
struct SimplePluginPingWorkflow {
    mutating func run(context: WorkflowContext<Self>, input: Void) async throws {}
}

@Suite(.tags(.pluginTests))
struct SimplePluginTests {

    // MARK: Client side

    @Test
    func clientInterceptorsAreAppended() {
        var configuration = TemporalClient.Configuration(
            instrumentation: .init(serverHostname: "localhost")
        )
        let initialCount = configuration.interceptors.count

        let plugin = SimplePlugin(
            name: "test",
            clientInterceptors: [TemporalClientTracingInterceptor()]
        )
        plugin.configure(&configuration)

        #expect(configuration.interceptors.count == initialCount + 1)
        #expect(configuration.interceptors.last is TemporalClientTracingInterceptor)
    }

    @Test
    func clientDataConverterClosureRunsWithExistingConverter() {
        var configuration = TemporalClient.Configuration(
            instrumentation: .init(serverHostname: "localhost")
        )
        let captured = Mutex<DataConverter?>(nil)

        let plugin = SimplePlugin(
            name: "test",
            dataConverter: { existing in
                captured.withLock { $0 = existing }
                return DataConverter(
                    payloadConverter: existing.payloadConverter,
                    failureConverter: existing.failureConverter,
                    payloadCodec: MarkerPayloadCodec()
                )
            }
        )
        plugin.configure(&configuration)

        #expect(captured.withLock { $0 != nil })
        #expect(configuration.dataConverter.payloadCodec is MarkerPayloadCodec)
    }

    @Test
    func clientDataConvertersComposeInArrayOrder() {
        // Two SimplePlugin instances each wrap the existing data converter via the
        // `dataConverter:` closure. Each closure records its own name on a shared chain;
        // when applyPlugins() runs, the recorded order must match the array order, proving
        // that the wrapping chain composes correctly (the Ruby/C# parity use case).
        let chain = Mutex<[String]>([])

        let firstName = "first"
        let secondName = "second"

        let first = SimplePlugin(
            name: firstName,
            dataConverter: { existing in
                chain.withLock { $0.append(firstName) }
                return existing
            }
        )
        let second = SimplePlugin(
            name: secondName,
            dataConverter: { existing in
                chain.withLock { $0.append(secondName) }
                return existing
            }
        )

        var configuration = TemporalClient.Configuration(
            instrumentation: .init(serverHostname: "localhost"),
            plugins: [first, second]
        )

        configuration.applyPlugins(logger: testLogger)

        #expect(chain.withLock { $0 } == [firstName, secondName])
    }

    // MARK: Worker side

    @Test
    func workerInterceptorsAreAppended() {
        var configuration = TemporalWorker.Configuration(
            namespace: "test",
            taskQueue: "test-queue",
            instrumentation: .init(serverHostname: "localhost")
        )
        let initialCount = configuration.interceptors.count

        let plugin = SimplePlugin(
            name: "test",
            workerInterceptors: [TemporalWorkerTracingInterceptor()]
        )
        plugin.configure(&configuration)

        #expect(configuration.interceptors.count == initialCount + 1)
        #expect(configuration.interceptors.last is TemporalWorkerTracingInterceptor)
    }

    // MARK: Replayer

    @Test
    func replayerInterceptorsAreAppended() {
        var configuration = WorkflowReplayer.Configuration()
        let initialCount = configuration.interceptors.count

        let plugin = SimplePlugin(
            name: "test",
            workerInterceptors: [TemporalWorkerTracingInterceptor()]
        )
        plugin.configureReplayer(&configuration)

        #expect(configuration.interceptors.count == initialCount + 1)
        #expect(configuration.interceptors.last is TemporalWorkerTracingInterceptor)
    }

    @Test
    func endToEndAutoApplyOnReplayer() {
        // Mirrors the fold performed by WorkflowReplayer.Configuration.applyPlugins(): it appends
        // each plugin's workflows to configuration.workflows. We exercise the same path here so
        // the pass criterion is an explicit assertion on configuration.workflows.
        let plugin = SimplePlugin(
            name: "test",
            workerInterceptors: [TemporalWorkerTracingInterceptor()],
            workflows: [SimplePluginPingWorkflow.self]
        )
        var configuration = WorkflowReplayer.Configuration(
            workflows: [],
            plugins: [plugin]
        )

        configuration.applyPlugins()

        #expect(configuration.workflows.contains { $0 == SimplePluginPingWorkflow.self })
    }
}
