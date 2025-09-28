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

import AsyncAlgorithms
import Foundation
import Logging
import Temporal
import TemporalTestKit
import Testing

extension TestServerDependentTests {
    @Suite(.tags(.workflowTests), .serialized)
    struct WorkflowSearchAttributeTests {
        static let attributeBool = SearchAttributeKey.bool("SwiftTemporalTestBool")
        static let attributeDate = SearchAttributeKey.date("SwiftTemporalTestDate")
        static let attributeDouble = SearchAttributeKey.double("SwiftTemporalTestDouble")
        static let attributeKeyword = SearchAttributeKey.keyword("SwiftTemporalTestKeyword")
        static let attributeKeywordList = SearchAttributeKey.keywordList("SwiftTemporalTestKeywordList")
        static let attributeInt = SearchAttributeKey.int("SwiftTemporalTestInt")
        static let attributeText = SearchAttributeKey.text("SwiftTemporalTestText")

        @Workflow
        final class SearchAttributesWorkflow {
            static let attributesInitial = SearchAttributeCollection {
                $0[attributeBool] = true
                $0[attributeDate] = Calendar.current.startOfDay(for: .now)
                $0[attributeDouble] = 123.45
                $0[attributeKeyword] = "SomeKeyword"
                $0[attributeKeywordList] = ["SomeKeyword1", "SomeKeyword2"]
                $0[attributeInt] = 678
                $0[attributeText] = "SomeText"
            }
            static let attributeFirstUpdates = SearchAttributeCollection {
                $0[attributeBool] = false
                $0[attributeDate] = Calendar.current.startOfDay(for: .now)
                $0[attributeDouble] = 234.56
                $0[attributeKeyword] = nil
                $0[attributeKeywordList] = nil
                $0[attributeInt] = nil
                $0[attributeText] = nil
            }
            static let attributeFirstUpdated = SearchAttributeCollection {
                $0[attributeBool] = attributeFirstUpdates[attributeBool]
                $0[attributeDate] = attributeFirstUpdates[attributeDate]
                $0[attributeDouble] = attributeFirstUpdates[attributeDouble]
            }
            static let attributeSecondUpdates = SearchAttributeCollection {
                $0[attributeBool] = nil
                $0[attributeDate] = nil
                $0[attributeDouble] = nil
                $0[attributeKeyword] = "AnotherKeyword"
                $0[attributeKeywordList] = ["SomeOtherKeyword3", "SomeOtherKeyword4"]
                $0[attributeInt] = 789
                $0[attributeText] = "SomeOtherText"
            }
            static let attributeSecondUpdated = SearchAttributeCollection {
                $0[attributeKeyword] = attributeSecondUpdates[attributeKeyword]
                $0[attributeKeywordList] = attributeSecondUpdates[attributeKeywordList]
                $0[attributeInt] = attributeSecondUpdates[attributeInt]
                $0[attributeText] = attributeSecondUpdates[attributeText]
            }

            private var proceed = false
            @WorkflowSignal
            func proceed(input: Void) async throws {
                proceed = true
            }

            func run(input: Void) async throws {
                #expect(Workflow.searchAttributes == Self.attributesInitial)

                try await Workflow.condition { self.proceed }
                proceed = false

                Workflow.upsertSearchAttributes(Self.attributeFirstUpdates)
                #expect(Workflow.searchAttributes == Self.attributeFirstUpdated)

                try await Workflow.condition { self.proceed }
                proceed = false

                Workflow.upsertSearchAttributes(Self.attributeSecondUpdates)
                #expect(Workflow.searchAttributes == Self.attributeSecondUpdated)
            }
        }

        private func ensureSearchAttributesPresent() async throws {
            try await TemporalTests.ensureSearchAttributesPresent(
                attributes: Self.attributeBool,
                Self.attributeDate,
                Self.attributeDouble,
                Self.attributeInt,
                Self.attributeKeyword,
                Self.attributeKeywordList,
                Self.attributeText
            )
        }

        @Test(.timeLimit(.minutes(1)))
        func searchAttributes() async throws {
            try await ensureSearchAttributesPresent()

            typealias Workflow = SearchAttributesWorkflow
            try await withTestWorkerAndClient(
                workflows: [Workflow.self]
            ) { taskQueue, client in
                let workflowID = UUID().uuidString
                let handle = try await client.startWorkflow(
                    type: Workflow.self,
                    options: .init(
                        id: workflowID,
                        taskQueue: taskQueue,
                        searchAttributes: Workflow.attributesInitial
                    )
                )

                // Confirm description shows initial
                let description = try await handle.describe()
                #expect(description.execution.searchAttributes == Workflow.attributesInitial)

                // Tell workflow to proceed and confirm next values
                try await handle.signal(signalType: Workflow.Proceed.self)

                try await expectWithRetry {
                    let currentAttributes = try await handle.describe().execution.searchAttributes.removingNonTestAttributes()
                    return currentAttributes == Workflow.attributeFirstUpdated
                }

                // Tell workflow to proceed and confirm next values
                try await handle.signal(signalType: Workflow.Proceed.self)

                try await expectWithRetry {
                    let currentAttributes = try await handle.describe().execution.searchAttributes.removingNonTestAttributes()
                    return currentAttributes == Workflow.attributeSecondUpdated
                }

                try await handle.result()
            }
        }

        @Workflow
        final class SimpleParentWorkflow {
            func run(input: Void) async throws -> String {
                try await Workflow.executeChildWorkflow(
                    SimpleWorkflow.self,
                    options: .init(
                        searchAttributes: .init {
                            $0[attributeInt] = 42
                        }
                    ),
                    input: ()
                )
            }
        }

        @Workflow
        final class SimpleWorkflow {
            func run(input: Void) async throws -> String {
                "\(Workflow.searchAttributes[attributeInt] ?? 0)-\(Workflow.searchAttributes[attributeKeyword] ?? "")-bar"
            }
        }

        @Test
        func filterBySearchAttributes() async throws {
            try await ensureSearchAttributesPresent()

            let id = UUID().uuidString
            let taskQueue = UUID().uuidString
            let executions = try await workflowHandle(
                for: SimpleWorkflow.self,
                input: (),
                searchAttributes: .init {
                    $0[Self.attributeKeyword] = "foo"
                },
                taskQueue: taskQueue,
                id: id
            ) {
                _ = try await $0.result()
                let executions = try await $0.untypedHandle.interceptor.listWorkflows(
                    .init(query: "\(Self.attributeKeyword) = 'foo' AND \(SearchAttributeKey.workflowType) = '\(SimpleWorkflow.name)'")
                )
                return try await Array(executions)
            }

            #expect(executions.count == 1)
            let execution = try #require(executions.first)
            #expect(execution.workflowType == "SimpleWorkflow")
            #expect(execution.parentRunID == nil)
            #expect(execution.parentWorkflowID == nil)
            #expect(execution.taskQueue == taskQueue)
            #expect(execution.searchAttributes[Self.attributeKeyword] == "foo")
        }

        @Test
        func addRemovalList() async throws {
            let randomKey = SearchAttributeKey.keyword(UUID().uuidString)

            try await withTestClient { client in
                let initialAttributes = try await client.listSearchAttributes()
                #expect(!initialAttributes.customAttributes.keys.contains(randomKey.name))

                try await client.addSearchAttributes(randomKey)
                let updatedAttributes = try await client.listSearchAttributes()
                #expect(updatedAttributes.customAttributes.keys.contains(randomKey.name))

                try await client.removeSearchAttributes(randomKey)
                let updatedAgainAttributes = try await client.listSearchAttributes()
                #expect(!updatedAgainAttributes.customAttributes.keys.contains(randomKey.name))
            }
        }

        @Test
        func childWorkflow() async throws {
            try await ensureSearchAttributesPresent()

            let result = try await executeWorkflow(
                SimpleParentWorkflow.self,
                input: (),
                moreWorkflows: [SimpleWorkflow.self],
                searchAttributes: .init {
                    $0[Self.attributeKeyword] = "test"
                }
            )
            #expect(result == "42-test-bar")
        }
    }
}

extension SearchAttributeCollection {
    func removingNonTestAttributes() -> Self {
        filter { $0.key.name.hasPrefix("Swift") }
    }
}

func expectWithRetry(
    iterations: Int = 30,
    interval: Duration = .milliseconds(300),
    _ condition: () async throws -> Bool,
    sourceLocation: SourceLocation = #_sourceLocation
) async throws {
    guard iterations > 0 else {
        fatalError("Expected at least one iteration, but got \(iterations)")
    }

    var iterationsLeft = iterations
    while iterationsLeft > 0 {
        iterationsLeft -= 1

        let result = try await condition()
        if result {
            return
        }

        try await Task.sleep(for: interval)
    }

    #expect(Bool(false), "Expected condition to evaluate to true within \(iterations) retries", sourceLocation: sourceLocation)
}
