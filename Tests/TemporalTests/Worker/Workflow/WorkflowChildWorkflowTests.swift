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

import Foundation
import Logging
import Synchronization
import Temporal
import TemporalTestKit
import Testing

extension TestServerDependentTests {
    @Suite(.tags(.workflowTests))
    struct WorkflowChildWorkflowTests {
        @Workflow
        struct SimpleChildWorkflow {
            enum Scenario: Codable {
                case `return`
                case fail
                case wait
            }
            struct Input: Codable {
                var scenario: Scenario
                var value: String
            }
            var didPay = false

            mutating func run(context: WorkflowContext<Self>, input: Input) async throws -> String {
                switch input.scenario {
                case .return:
                    return input.value
                case .fail:
                    let detail1 = try context.payloadConverter.convertValue("detail1")
                    let detail2 = try context.payloadConverter.convertValue("detail2")
                    throw ApplicationError(message: "Intentional failure", details: [detail1, detail2])
                case .wait:
                    try await context.condition { false }
                    fatalError()
                }
            }
        }
        @Workflow
        struct SimpleParentWorkflow {
            enum Scenario: Codable {
                case success
                case fail
                case alreadyExists
            }
            struct Input: Codable {
                var scenario: Scenario
                var value: String
            }

            mutating func run(context: WorkflowContext<Self>, input: Input) async throws -> [String] {
                switch input.scenario {
                case .success:
                    let first = try await context.executeChildWorkflow(
                        SimpleChildWorkflow.self,
                        input: .init(scenario: .return, value: input.value)
                    )
                    let second = try await context.executeChildWorkflow(
                        SimpleChildWorkflow.self,
                        input: .init(scenario: .return, value: input.value)
                    )
                    let third = try await context.executeChildWorkflow(
                        SimpleChildWorkflow.self,
                        input: .init(scenario: .return, value: input.value)
                    )
                    return [first, second, third]
                case .fail:
                    _ = try await context.executeChildWorkflow(
                        SimpleChildWorkflow.self,
                        input: .init(scenario: .fail, value: "")
                    )
                    fatalError()

                case .alreadyExists:
                    let handle = try await context.startChildWorkflow(
                        SimpleChildWorkflow.self,
                        input: .init(scenario: .wait, value: "")
                    )
                    var options = ChildWorkflowOptions()
                    options.id = handle.id
                    _ = try await context.startChildWorkflow(
                        SimpleChildWorkflow.self,
                        options: options,
                        input: .init(scenario: .wait, value: "")
                    )
                    fatalError()
                }
            }
        }

        @Workflow
        struct CancelChildWorkflow {
            mutating func run(context: WorkflowContext<Self>, input: Void) async throws -> String {
                do {
                    try await context.condition { false }
                    fatalError()
                } catch is CanceledError {
                    return "Done"
                } catch {
                    throw error
                }
            }
        }

        @Workflow
        struct CancelParentWorkflow {
            enum Scenario: Codable {
                case cancelWait
                case cancelTry
            }

            mutating func run(context: WorkflowContext<Self>, input: Scenario) async throws -> String {
                switch input {
                case .cancelWait:
                    let handle = try await context.startChildWorkflow(
                        CancelChildWorkflow.self,
                        options: .init(),
                        input: ()
                    )
                    return try await context.timeout(for: .seconds(0.1)) {
                        try await handle.result()
                    }

                case .cancelTry:
                    let handle = try await context.startChildWorkflow(
                        CancelChildWorkflow.self,
                        options: .init(cancellationType: .tryCancel),
                        input: ()
                    )
                    return try await context.timeout(for: .seconds(0.1)) {
                        try await handle.result()
                    }
                }
            }
        }

        @Test
        func simpleSuccess() async throws {
            let result = try await executeWorkflow(
                SimpleParentWorkflow.self,
                input: .init(scenario: .success, value: "return"),
                moreWorkflows: [SimpleChildWorkflow.self],
            )

            #expect(result == ["return", "return", "return"])
        }

        @Test
        func simpleFail() async throws {
            let error = try await #require(throws: WorkflowFailedError.self) {
                try await executeWorkflow(
                    SimpleParentWorkflow.self,
                    input: .init(scenario: .fail, value: "return"),
                    moreWorkflows: [SimpleChildWorkflow.self],
                )
            }

            let childWorkflowError = try #require(error.cause as? ChildWorkflowError)
            let applicationError = try #require(childWorkflowError.cause as? ApplicationError)
            let detail1 = try await DataConverter.default.convertValue("detail1")
            let detail2 = try await DataConverter.default.convertValue("detail2")
            #expect(applicationError.details == [detail1, detail2])
        }

        @Test
        func simpleAlreadyExists() async throws {
            let error = try await #require(throws: WorkflowFailedError.self) {
                try await executeWorkflow(
                    SimpleParentWorkflow.self,
                    input: .init(scenario: .alreadyExists, value: "return"),
                    moreWorkflows: [SimpleChildWorkflow.self],
                )
            }

            let applicationError = try #require(error.cause as? ApplicationError)
            #expect(applicationError.message == "Workflow execution already started")
        }

        @Test
        func cancelWait() async throws {
            let result = try await executeWorkflow(
                CancelParentWorkflow.self,
                input: .cancelWait,
                moreWorkflows: [CancelChildWorkflow.self],
            )
            #expect(result == "Done")
        }

        @Test
        func cancelTry() async throws {
            let error = try await #require(throws: WorkflowFailedError.self) {
                try await executeWorkflow(
                    CancelParentWorkflow.self,
                    input: .cancelTry,
                    moreWorkflows: [CancelChildWorkflow.self],
                )
            }

            let childWorkflowError = try #require(error.cause as? ChildWorkflowError)
            #expect(childWorkflowError.cause is CanceledError)
        }

        @Test
        func interceptsStart() async throws {
            final class CountingInterceptor: WorkerInterceptor {
                let counter: Mutex<Int> = .init(0)

                struct Outbound: WorkflowOutboundInterceptor {
                    let interceptor: CountingInterceptor

                    func startChildWorkflow<each Input>(
                        input: StartChildWorkflowInput<repeat each Input>,
                        next: (StartChildWorkflowInput<repeat each Input>) async throws -> UntypedChildWorkflowHandle
                    ) async throws -> UntypedChildWorkflowHandle {
                        interceptor.counter.withLock { $0 += 1 }
                        return try await next(input)
                    }
                }

                var workflowOutboundInterceptor: Outbound? {
                    return Outbound(interceptor: self)
                }
            }

            let interceptor = CountingInterceptor()

            let result = try await executeWorkflow(
                SimpleParentWorkflow.self,
                input: .init(scenario: .success, value: "return"),
                moreWorkflows: [SimpleChildWorkflow.self],
                interceptors: [interceptor]
            )

            #expect(interceptor.counter.withLock { $0 } >= 3)

            #expect(result == ["return", "return", "return"])
        }

        @Workflow
        struct SignalChildWorkflow {
            enum Scenario: Codable {
                case wait
                case finish
            }

            var signals = [String]()

            mutating func run(context: WorkflowContext<Self>, input: Scenario) async throws -> String {
                switch input {
                case .wait:
                    try await context.condition { false }
                    return "done"
                case .finish:
                    return "done"
                }
            }

            @WorkflowSignal
            mutating func signal(input: String) {
                self.signals.append(input)
            }

            @WorkflowQuery
            func query(input: Void) -> [String] {
                self.signals
            }
        }

        @Workflow
        struct SignalParentWorkflow {
            enum Scenario: Codable {
                case signal
                case signalButDone
                case signalThenCancel
            }

            mutating func run(context: WorkflowContext<Self>, input: Scenario) async throws -> String {
                switch input {
                case .signal:
                    let handle = try await context.startChildWorkflow(
                        SignalChildWorkflow.self,
                        options: .init(),
                        input: .wait
                    )
                    try await handle.signalWorkflow(
                        signalType: SignalChildWorkflow.Signal.self,
                        input: "foo"
                    )
                    try await handle.signalWorkflow(
                        signalType: SignalChildWorkflow.Signal.self,
                        input: "bar"
                    )
                    return handle.id
                case .signalButDone:
                    let handle = try await context.startChildWorkflow(
                        SignalChildWorkflow.self,
                        options: .init(),
                        input: .finish
                    )
                    _ = try await handle.result()
                    try await handle.signalWorkflow(
                        signalType: SignalChildWorkflow.Signal.self,
                        input: "bar"
                    )
                    return handle.id
                case .signalThenCancel:
                    let handle = try await context.startChildWorkflow(
                        SignalChildWorkflow.self,
                        options: .init(),
                        input: .finish
                    )
                    try await withThrowingTaskGroup { group in
                        group.addTask {
                            try await handle.signalWorkflow(
                                signalType: SignalChildWorkflow.Signal.self,
                                input: "bar"
                            )
                        }
                        // This child task is used to so that we enqueue the command
                        // to signal the workflow but also cancel the signal
                        // in the same task
                        group.addTask {}
                        try await group.next()
                        group.cancelAll()
                        try await group.next()
                    }
                    return handle.id
                }
            }
        }

        @Test
        func testSignal() async throws {
            _ = try await executeWorkflow(
                SignalParentWorkflow.self,
                input: .signal,
                moreWorkflows: [SignalChildWorkflow.self],
            ) { handle, childID in
                let signals = try await handle.with(id: childID).query(queryType: SignalChildWorkflow.Query.self)
                #expect(signals == ["foo", "bar"])
            }
        }

        @Test
        func testSignalButDone() async throws {
            let error = try await #require(throws: WorkflowFailedError.self) {
                try await executeWorkflow(
                    SignalParentWorkflow.self,
                    input: .signalButDone,
                    moreWorkflows: [SignalChildWorkflow.self],
                )
            }

            let applicationError = try #require(error.cause as? ApplicationError)
            #expect(applicationError.message == "Unable to signal external workflow because it was not found")
        }

        @Test
        func testSignalThenCancel() async throws {
            let error = try await #require(throws: WorkflowFailedError.self) {
                try await executeWorkflow(
                    SignalParentWorkflow.self,
                    input: .signalThenCancel,
                    moreWorkflows: [SignalChildWorkflow.self],
                )
            }

            let cancelledError = try #require(error.cause as? CanceledError)
            #expect(cancelledError.message == "Signal was cancelled before being sent")
        }

        @Workflow
        struct ParentClosePolicyChildWorkflow {
            private var finished = false

            mutating func run(context: WorkflowContext<Self>, input: Void) async throws {
                try await context.condition { $0.finished }
            }

            @WorkflowSignal
            mutating func signal(input: Void) {
                self.finished = true
            }
        }

        @Workflow
        struct ParentClosePolicyParentWorkflow {
            enum Scenario: Codable {
                case parentCloseTerminate
                case parentCloseRequestCancel
                case parentCloseAbandon
            }

            mutating func run(context: WorkflowContext<Self>, input: Scenario) async throws -> String {
                switch input {
                case .parentCloseTerminate:
                    let handle = try await context.startChildWorkflow(
                        ParentClosePolicyChildWorkflow.self,
                        options: .init(),
                        input: ()
                    )
                    return handle.id
                case .parentCloseRequestCancel:
                    let handle = try await context.startChildWorkflow(
                        ParentClosePolicyChildWorkflow.self,
                        options: .init(parentClosePolicy: .requestCancel),
                        input: ()
                    )
                    return handle.id
                case .parentCloseAbandon:
                    let handle = try await context.startChildWorkflow(
                        ParentClosePolicyChildWorkflow.self,
                        options: .init(parentClosePolicy: .abandon),
                        input: ()
                    )
                    return handle.id
                }
            }
        }

        @Test
        func parentCloseTerminate() async throws {
            _ = try await executeWorkflow(
                ParentClosePolicyParentWorkflow.self,
                input: .parentCloseTerminate,
                moreWorkflows: [ParentClosePolicyChildWorkflow.self],
            ) { handle, childID in
                let error = try await #require(throws: WorkflowFailedError.self) {
                    try await handle
                        .with(id: childID)
                        .with(resultRunID: nil)  // need to clear resulting run ID
                        .with(workflowType: ParentClosePolicyChildWorkflow.self)
                        .result()
                }

                let terminatedError = try #require(error.cause as? TerminatedError)
                #expect(terminatedError.message == "Workflow execution terminated: by parent close policy")
            }
        }

        @Test
        func parentCloseRequestCancel() async throws {
            _ = try await executeWorkflow(
                ParentClosePolicyParentWorkflow.self,
                input: .parentCloseRequestCancel,
                moreWorkflows: [ParentClosePolicyChildWorkflow.self],
            ) { handle, childID in
                let error = try await #require(throws: WorkflowFailedError.self) {
                    try await handle
                        .with(id: childID)
                        .with(resultRunID: nil)  // need to clear resulting run ID
                        .with(workflowType: ParentClosePolicyChildWorkflow.self)
                        .result()
                }

                // `workflowExecutionCanceled` command translates to exactly this error
                let cancelledError = try #require(error.cause as? CanceledError)
                #expect(cancelledError.message == "Workflow execution canceled")
            }
        }

        @Test
        func parentCloseAbandon() async throws {
            _ = try await executeWorkflow(
                ParentClosePolicyParentWorkflow.self,
                input: .parentCloseAbandon,
                moreWorkflows: [ParentClosePolicyChildWorkflow.self],
            ) { handle, childID in
                try await handle
                    .with(id: childID)
                    .signal(signalType: ParentClosePolicyChildWorkflow.Signal.self)

                try await handle
                    .with(id: childID)
                    .with(resultRunID: nil)  // need to clear resulting run ID
                    .with(workflowType: ParentClosePolicyChildWorkflow.self)
                    .result()
            }
        }

        @Test
        func interceptSignal() async throws {
            final class CountingInterceptor: WorkerInterceptor {
                let counter: Mutex<Int> = .init(0)

                struct Outbound: WorkflowOutboundInterceptor {
                    let interceptor: CountingInterceptor

                    func signalWorkflow<each Input>(
                        input: SignalChildWorkflowInput<repeat each Input>,
                        next: (SignalChildWorkflowInput<repeat each Input>) async throws -> Void
                    ) async throws {
                        #expect(input.name == "Signal")
                        interceptor.counter.withLock { $0 += 1 }
                        try await next(input)
                    }
                }

                var workflowOutboundInterceptor: Outbound? {
                    return Outbound(interceptor: self)
                }
            }

            let interceptor = CountingInterceptor()

            _ = try await executeWorkflow(
                SignalParentWorkflow.self,
                input: .signal,
                moreWorkflows: [SignalChildWorkflow.self],
                interceptors: [interceptor]
            ) { handle, childID in
                let signals =
                    try await handle
                    .with(id: childID)
                    .query(queryType: SignalChildWorkflow.Query.self)

                #expect(signals == ["foo", "bar"])
            }

            #expect(interceptor.counter.withLock { $0 } >= 2)
        }

        @Workflow
        struct ChildMemoAndRetryWorkflow {
            mutating func run(context: WorkflowContext<Self>, input: Void) async throws {
                guard let memo = try await context.getMemoValue(for: "hello", as: String.self) else {
                    throw ApplicationError(message: "Workflow memo not found!", isNonRetryable: true)
                }

                guard memo == "world" else {
                    throw ApplicationError(message: "Workflow memo has invalid value: \(memo)!", isNonRetryable: true)
                }

                guard let retryPolicy = context.info.retryPolicy,
                    retryPolicy.maximumAttempts == 30
                else {
                    throw ApplicationError(message: "Retry Policy is not present!", isNonRetryable: true)
                }
            }
        }

        @Workflow
        struct ParentMemoAndRetryWorkflow {
            mutating func run(context: WorkflowContext<Self>, input: Void) async throws {
                try await context.executeChildWorkflow(
                    ChildMemoAndRetryWorkflow.self,
                    options: ChildWorkflowOptions(
                        retryPolicy: .init(maximumAttempts: 30),
                        memo: ["hello": "world"]
                    ),
                    input: ()
                )
            }
        }

        @Test
        func childWorkflowMemoAndRetryPolicy() async throws {
            await #expect(throws: Never.self) {
                try await executeWorkflow(ParentMemoAndRetryWorkflow.self, input: (), moreWorkflows: [ChildMemoAndRetryWorkflow.self])
            }
        }

        @Workflow
        struct ChildWorkflow {
            struct Input: Codable {
                let id: Int
            }

            mutating func run(context: WorkflowContext<Self>, input: Input) async throws {
                try await context.sleep(for: .seconds(3600))
            }
        }

        @Workflow
        struct ParentWorkflow {
            mutating func run(context: WorkflowContext<Self>, input: Void) async throws {
                let logger = context.logger
                var ids: [Int] = []
                ids.reserveCapacity(150)
                for index in 0..<150 {
                    ids.append(index)
                }

                var handles: [ChildWorkflowHandle<ChildWorkflow>] = []
                handles.reserveCapacity(ids.count)

                _ = context.patch("starting child-workflows ...")

                for id in ids {
                    do {
                        let handle = try await context.startChildWorkflow(ChildWorkflow.self, input: .init(id: id))
                        handles.append(handle)
                    } catch is CanceledError {
                        logger.info("Workflow cancelled skipping start of the other child workflows.")
                        break
                    } catch {
                        logger.info("Starting child workflow failed: \(error)")
                        throw error
                    }
                }

                _ = context.patch("started child-workflows")

                var successfulWorkflows = 0
                var cancelledWorkflows = 0
                var erroneousWorkflows = 0

                for handle in handles {
                    do {
                        try await handle.result()
                        successfulWorkflows += 1
                    } catch let error as ChildWorkflowError where error.cause is CanceledError {
                        cancelledWorkflows += 1
                    } catch {
                        erroneousWorkflows += 1
                    }
                }

                logger.info(
                    "Workflow completed",
                    metadata: [
                        "success": "\(successfulWorkflows)",
                        "cancelled": "\(cancelledWorkflows)",
                        "errors": "\(erroneousWorkflows)",
                    ]
                )

                if Task.isCancelled {
                    throw CanceledError(message: "Workflow was cancelled!")
                }
            }
        }

        @Test("Cancellation Test")
        func cancellationTest() async throws {
            try await withTestWorkerAndClient(workflows: [ChildWorkflow.self, ParentWorkflow.self]) { taskQueue, client in
                let handle = try await client.startWorkflow(
                    type: ParentWorkflow.self,
                    options: .init(id: UUID().uuidString.lowercased(), taskQueue: taskQueue)
                )

                // let's spawn a few child workflows
                try await _Concurrency.Task.sleep(for: .seconds(3))

                try await handle.cancel()

                let error = try await #require(throws: WorkflowFailedError.self) {
                    try await handle.result()
                }

                #expect(error.cause is CanceledError)
                if error.description.contains("TMPRL1100") {
                    Issue.record(error)
                } else if error.cause is CanceledError {
                    // It worked
                } else {
                    Issue.record(error, "Unexpected error")
                }
            }
        }
    }
}
