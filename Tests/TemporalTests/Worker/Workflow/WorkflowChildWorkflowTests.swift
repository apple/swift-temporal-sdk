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

import Synchronization
import Temporal
import TemporalTestKit
import Testing

extension TestServerDependentTests {
    @Suite(.tags(.workflowTests))
    struct WorkflowChildWorkflowTests {
        @Workflow
        final class SimpleChildWorkflow {
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

            func run(input: Input) async throws -> String {
                switch input.scenario {
                case .return:
                    return input.value
                case .fail:
                    let detail1 = try Workflow.payloadConverter.convertValue("detail1")
                    let detail2 = try Workflow.payloadConverter.convertValue("detail2")
                    throw ApplicationError(message: "Intentional failure", details: [detail1, detail2])
                case .wait:
                    try await Workflow.condition { false }
                    fatalError()
                }
            }
        }
        @Workflow
        final class SimpleParentWorkflow {
            enum Scenario: Codable {
                case success
                case fail
                case alreadyExists
            }
            struct Input: Codable {
                var scenario: Scenario
                var value: String
            }

            func run(input: Input) async throws -> [String] {
                switch input.scenario {
                case .success:
                    let first = try await Workflow.executeChildWorkflow(
                        SimpleChildWorkflow.self,
                        input: .init(scenario: .return, value: input.value)
                    )
                    let second = try await Workflow.executeChildWorkflow(
                        SimpleChildWorkflow.self,
                        input: .init(scenario: .return, value: input.value)
                    )
                    let third = try await Workflow.executeChildWorkflow(
                        SimpleChildWorkflow.self,
                        input: .init(scenario: .return, value: input.value)
                    )
                    return [first, second, third]
                case .fail:
                    _ = try await Workflow.executeChildWorkflow(
                        SimpleChildWorkflow.self,
                        input: .init(scenario: .fail, value: "")
                    )
                    fatalError()

                case .alreadyExists:
                    let handle = try await Workflow.startChildWorkflow(
                        SimpleChildWorkflow.self,
                        input: .init(scenario: .wait, value: "")
                    )
                    var options = ChildWorkflowOptions()
                    options.id = handle.id
                    _ = try await Workflow.startChildWorkflow(
                        SimpleChildWorkflow.self,
                        options: options,
                        input: .init(scenario: .wait, value: "")
                    )
                    fatalError()
                }
            }
        }

        @Workflow
        final class CancelChildWorkflow {
            func run(input: Void) async throws -> String {
                do {
                    try await Workflow.condition { false }
                    fatalError()
                } catch is CanceledError {
                    return "Done"
                } catch {
                    throw error
                }
            }
        }

        @Workflow
        final class CancelParentWorkflow {
            enum Scenario: Codable {
                case cancelWait
                case cancelTry
            }

            func run(input: Scenario) async throws -> String {
                switch input {
                case .cancelWait:
                    let handle = try await Workflow.startChildWorkflow(
                        CancelChildWorkflow.self,
                        options: .init(),
                        input: ()
                    )
                    return try await Workflow.timeout(for: .seconds(0.1)) {
                        try await handle.result()
                    }

                case .cancelTry:
                    let handle = try await Workflow.startChildWorkflow(
                        CancelChildWorkflow.self,
                        options: .init(cancellationType: .tryCancel),
                        input: ()
                    )
                    return try await Workflow.timeout(for: .seconds(0.1)) {
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

                func makeWorkflowOutboundInterceptor() -> Outbound? {
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

            #expect(interceptor.counter.withLock { $0 } == 3)

            #expect(result == ["return", "return", "return"])
        }

        @Workflow
        final class SignalChildWorkflow {
            enum Scenario: Codable {
                case wait
                case finish
            }

            var signals = [String]()

            func run(input: Scenario) async throws -> String {
                switch input {
                case .wait:
                    try await Workflow.condition { false }
                    return "done"
                case .finish:
                    return "done"
                }
            }

            @WorkflowSignal
            func signal(input: String) {
                self.signals.append(input)
            }

            @WorkflowQuery
            func query(input: Void) -> [String] {
                self.signals
            }
        }

        @Workflow
        final class SignalParentWorkflow {
            enum Scenario: Codable {
                case signal
                case signalButDone
                case signalThenCancel
            }

            func run(input: Scenario) async throws -> String {
                switch input {
                case .signal:
                    let handle = try await Workflow.startChildWorkflow(
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
                    let handle = try await Workflow.startChildWorkflow(
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
                    let handle = try await Workflow.startChildWorkflow(
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
        final class ParentClosePolicyChildWorkflow {
            private var finished = false

            func run(input: Void) async throws {
                try await Workflow.condition { self.finished }
            }

            @WorkflowSignal
            func signal(input: Void) {
                self.finished = true
            }
        }

        @Workflow
        final class ParentClosePolicyParentWorkflow {
            enum Scenario: Codable {
                case parentCloseTerminate
                case parentCloseRequestCancel
                case parentCloseAbandon
            }

            func run(input: Scenario) async throws -> String {
                switch input {
                case .parentCloseTerminate:
                    let handle = try await Workflow.startChildWorkflow(
                        ParentClosePolicyChildWorkflow.self,
                        options: .init(),
                        input: ()
                    )
                    return handle.id
                case .parentCloseRequestCancel:
                    let handle = try await Workflow.startChildWorkflow(
                        ParentClosePolicyChildWorkflow.self,
                        options: .init(parentClosePolicy: .requestCancel),
                        input: ()
                    )
                    return handle.id
                case .parentCloseAbandon:
                    let handle = try await Workflow.startChildWorkflow(
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

                let cancelledError = try #require(error.cause as? CanceledError)
                #expect(cancelledError.message == "Wait condition cancelled")
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

                func makeWorkflowOutboundInterceptor() -> Outbound? {
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

            #expect(interceptor.counter.withLock { $0 } == 2)
        }
    }
}
