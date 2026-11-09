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

import Temporal
import Testing

@Suite(.tags(.workflowTests))
struct WorkflowFailureErrorTypesTests {
    struct DomainError: Error {}
    struct OtherError: Error {}
    class BaseError: Error, @unchecked Sendable {}
    final class SubError: BaseError, @unchecked Sendable {}

    @Workflow
    struct PlainWorkflow {
        func run(context: WorkflowContext<Self>, input: Void) async throws {}
    }

    @Workflow(failureErrorTypes: [WorkflowNondeterminismError.self])
    struct NondeterminismFailingWorkflow {
        func run(context: WorkflowContext<Self>, input: Void) async throws {}
    }

    @Workflow(failureErrorTypes: [DomainError.self])
    struct DomainFailingWorkflow {
        func run(context: WorkflowContext<Self>, input: Void) async throws {}
    }

    @Workflow(failureErrorTypes: [(any Error).self])
    struct ErrorFailingWorkflow {
        func run(context: WorkflowContext<Self>, input: Void) async throws {}
    }

    @Test
    func workflowDefinitionDefaultsToNoFailureErrorTypes() {
        #expect(PlainWorkflow.failureErrorTypes.isEmpty)
    }

    // MARK: - Matching

    @Test
    func matchesListedType() {
        #expect(WorkflowFailureErrorTypes([DomainError.self]).contains(DomainError()))
    }

    @Test
    func doesNotMatchOtherTypes() {
        let types = WorkflowFailureErrorTypes([DomainError.self])
        #expect(!types.contains(OtherError()))
        #expect(!types.contains(ApplicationError(message: "boom")))
    }

    @Test
    func listedClassMatchesItsSubclasses() {
        let types = WorkflowFailureErrorTypes([BaseError.self])
        #expect(types.contains(BaseError()))
        #expect(types.contains(SubError()))
    }

    @Test
    func listedErrorMatchesEveryError() {
        let types = WorkflowFailureErrorTypes([(any Error).self])
        #expect(types.contains(DomainError()))
        #expect(types.contains(ApplicationError(message: "boom")))
    }

    // MARK: - Nondeterminism

    @Test
    func nondeterminismIsMatchedByListedNondeterminismError() {
        #expect(WorkflowFailureErrorTypes([DomainError.self, WorkflowNondeterminismError.self]).matchesNondeterminism)
        #expect(!WorkflowFailureErrorTypes([DomainError.self]).matchesNondeterminism)
        #expect(!WorkflowFailureErrorTypes([]).matchesNondeterminism)
    }

    @Test
    func nondeterminismIsMatchedByListedError() {
        #expect(WorkflowFailureErrorTypes([(any Error).self]).matchesNondeterminism)
    }

    @Test
    func workflowTypesFailingOnNondeterminismOnlyIncludesMatchingWorkflows() {
        let workflowTypes = WorkflowFailureErrorTypes.workflowTypesFailingOnNondeterminism(
            in: [PlainWorkflow.self, NondeterminismFailingWorkflow.self, DomainFailingWorkflow.self, ErrorFailingWorkflow.self]
        )
        #expect(workflowTypes == [NondeterminismFailingWorkflow.name, ErrorFailingWorkflow.name])
    }
}
