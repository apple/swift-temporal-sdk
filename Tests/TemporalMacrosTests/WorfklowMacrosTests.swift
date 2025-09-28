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

import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import Testing

@Suite(.tags(.macroTests))
struct WorkflowMacrosTests {
    @Test
    func simple() throws {
        let (expectedOutput, _) = try parse(
            """
            final class Foo {

                required init(input: Input) {}
            }

            extension Foo: WorkflowDefinition {
            }
            """
        )
        let (actualOutput, _) = try parse(
            """
            @Workflow
            final class Foo {}
            """
        )
        #expect(expectedOutput == actualOutput)
    }

    @Test(arguments: ["public", "package", "internal", "fileprivate"])
    func accessModifier(modifier: String) throws {
        let (expectedOutput, _) = try parse(
            """
            \(modifier) final class Foo {
                func fooSignal(input: String) async throws {}

                struct FooSignal: WorkflowSignalDefinition {
                    typealias Input = String
                    typealias Workflow = Foo

                    let _run: @Sendable (Workflow, Input) async throws -> Void
                    init(run: @Sendable @escaping (Workflow, Input) async throws -> Void) {
                        self._run = run
                    }
                    func run(workflow: Workflow, input: Input) async throws {
                        try await self._run(workflow, input)
                    }


                }

                static var fooSignal: FooSignal {
                    FooSignal(run: {
                            try await $0.fooSignal(input: $1)
                        })
                }
                func fooQuery(input: String) throws -> String {}

                struct FooQuery: WorkflowQueryDefinition {
                    typealias Input = String
                    typealias Output = String
                    typealias Workflow = Foo

                    let _run: @Sendable (Workflow, Input) throws -> Output
                    init(run: @Sendable @escaping (Workflow, Input) throws -> Output) {
                        self._run = run
                    }
                    func run(workflow: Workflow, input: Input) throws -> Output {
                        try self._run(workflow, input)
                    }


                }

                static var fooQuery: FooQuery {
                    FooQuery(run: {
                            try $0.fooQuery(input: $1)
                        })
                }
                func fooUpdate(input: String) async throws -> Int {}

                struct FooUpdate: WorkflowUpdateDefinition {
                    typealias Input = String
                    typealias Output = Int
                    typealias Workflow = Foo

                    let _run: @Sendable (Workflow, Input) async throws -> Output
                    init(run: @Sendable @escaping (Workflow, Input) async throws -> Output) {
                        self._run = run
                    }
                    func run(workflow: Workflow, input: Input) async throws -> Output {
                        try await self._run(workflow, input)
                    }


                }

                static var fooUpdate: FooUpdate {
                    FooUpdate(run: {
                            try await $0.fooUpdate(input: $1)
                        })
                }

                \(modifier) static var signals: [any WorkflowSignalDefinition<Foo>] {
                    [Self.fooSignal]
                }

                \(modifier) static var queries: [any WorkflowQueryDefinition<Foo>] {
                    [Self.fooQuery]
                }

                \(modifier) static var updates: [any WorkflowUpdateDefinition<Foo>] {
                    [Self.fooUpdate]
                }

                \(modifier) required init(input: Input) {}
            }

            extension Foo: WorkflowDefinition {
                \(modifier) static var name: String { "CustomName" }
            }
            """
        )
        let (actualOutput, _) = try parse(
            """
            @Workflow(name: "CustomName")
            \(modifier) final class Foo {
                @WorkflowSignal
                func fooSignal(input: String) async throws {}
                @WorkflowQuery
                func fooQuery(input: String) throws -> String {}
                @WorkflowUpdate
                func fooUpdate(input: String) async throws -> Int {}
            }
            """
        )
        #expect(expectedOutput == actualOutput)
    }

    @Test
    func namedWorkflow() throws {
        let (expectedOutput, _) = try parse(
            """
            final class Foo {

                required init(input: Input) {}
            }

            extension Foo: WorkflowDefinition {
                static var name: String { "CustomName" }
            }
            """
        )
        let (actualOutput, _) = try parse(
            """
            @Workflow(name: "CustomName")
            final class Foo {}
            """
        )
        #expect(expectedOutput == actualOutput)
    }

    @Test(arguments: [nil, "public", "package", "internal", "fileprivate", "private"])
    func signal(modifier: String?) throws {
        let modifierPrefix = modifier.map { "\($0) " } ?? ""

        let (expectedOutput, _) = try parse(
            """
            final class FooWorkflow {
                \(modifierPrefix)func foo(input: String) async throws {} 

                \(modifierPrefix)struct Foo: WorkflowSignalDefinition {
                    \(modifierPrefix)typealias Input = String
                    \(modifierPrefix)typealias Workflow = FooWorkflow

                    let _run: @Sendable (Workflow, Input) async throws -> Void
                    init(run: @Sendable @escaping (Workflow, Input) async throws -> Void) {
                        self._run = run
                    }
                    \(modifierPrefix)func run(workflow: Workflow, input: Input) async throws {
                        try await self._run(workflow, input)
                    }
                }

                static var foo: Foo {
                    Foo(run: {
                            try await $0.foo(input: $1)
                        })
                }
                \(modifierPrefix)func bar(input: Void) async throws {
                }

                \(modifierPrefix)struct Bar: WorkflowSignalDefinition {
                    \(modifierPrefix)typealias Input = Void
                    \(modifierPrefix)typealias Workflow = FooWorkflow

                    let _run: @Sendable (Workflow, Input) async throws -> Void
                    init(run: @Sendable @escaping (Workflow, Input) async throws -> Void) {
                        self._run = run
                    }
                    \(modifierPrefix)func run(workflow: Workflow, input: Input) async throws {
                        try await self._run(workflow, input)
                    }
                    \(modifierPrefix)static var name: String {
                        "MySignal"
                    }
                    \(modifierPrefix)static var description: String? {
                        "This is a description."
                    }
                }

                static var bar: Bar {
                    Bar(run: {
                            try await $0.bar(input: $1)
                        })
                }

                static var signals: [any WorkflowSignalDefinition<FooWorkflow>] {
                    [Self.foo, Self.bar]
                }

                required init(input: Input) {}
            }

            extension FooWorkflow: WorkflowDefinition {
            }
            """,
            removeWhitespace: true
        )
        let (actualOutput, _) = try parse(
            """
            @Workflow
            final class FooWorkflow {
                @WorkflowSignal
                \(modifierPrefix)func foo(input: String) async throws {}
                @WorkflowSignal(name: "MySignal", description: "This is a description.")
                \(modifierPrefix)func bar(input: Void) async throws {}
            }
            """,
            removeWhitespace: true
        )
        #expect(expectedOutput == actualOutput)
    }

    @Test(arguments: [nil, "public", "package", "internal", "fileprivate", "private"])
    func query(modifier: String?) throws {
        let modifierPrefix = modifier.map { "\($0) " } ?? ""

        let (expectedOutput, _) = try parse(
            """
            final class FooWorkflow {
                \(modifierPrefix)func foo(input: String) throws -> String {} 

                \(modifierPrefix)struct Foo: WorkflowQueryDefinition {
                    \(modifierPrefix)typealias Input = String
                    \(modifierPrefix)typealias Output = String
                    \(modifierPrefix)typealias Workflow = FooWorkflow

                    let _run: @Sendable (Workflow, Input) throws -> Output
                    init(run: @Sendable @escaping (Workflow, Input) throws -> Output) {
                        self._run = run
                    }
                    \(modifierPrefix)func run(workflow: Workflow, input: Input) throws -> Output{
                        try self._run(workflow, input)
                    }
                }

                static var foo: Foo {
                    Foo(run: {
                            try $0.foo(input: $1)
                        })
                }
                \(modifierPrefix)func bar(input: Void) throws -> Int {
                }

                \(modifierPrefix)struct Bar: WorkflowQueryDefinition {
                    \(modifierPrefix)typealias Input = Void
                    \(modifierPrefix)typealias Output = Int
                    \(modifierPrefix)typealias Workflow = FooWorkflow

                    let _run: @Sendable (Workflow, Input) throws -> Output
                    init(run: @Sendable @escaping (Workflow, Input) throws -> Output) {
                        self._run = run
                    }
                    \(modifierPrefix)func run(workflow: Workflow, input: Input) throws -> Output{
                        try self._run(workflow, input)
                    }
                    \(modifierPrefix)static var name: String {
                        "MyQuery"
                    }
                    \(modifierPrefix)static var description: String? {
                        "This is a description."
                    }
                }

                static var bar: Bar {
                    Bar(run: {
                            try $0.bar(input: $1)
                        })
                }

                static var queries: [any WorkflowQueryDefinition<FooWorkflow>] {
                    [Self.foo, Self.bar]
                }

                required init(input: Input) {}
            }

            extension FooWorkflow: WorkflowDefinition {
            }
            """,
            removeWhitespace: true
        )
        let (actualOutput, _) = try parse(
            """
            @Workflow
            final class FooWorkflow {
                @WorkflowQuery
                \(modifierPrefix)func foo(input: String) throws -> String {}
                @WorkflowQuery(name: "MyQuery", description: "This is a description.")
                \(modifierPrefix)func bar(input: Void) throws -> Int {}
            }
            """,
            removeWhitespace: true
        )
        #expect(expectedOutput == actualOutput)
    }

    @Test(arguments: [nil, "public", "package", "internal", "fileprivate", "private"])
    func update(modifier: String?) throws {
        let modifierPrefix = modifier.map { "\($0) " } ?? ""

        let (expectedOutput, _) = try parse(
            """
            final class FooWorkflow {
                \(modifierPrefix)func foo(input: String) async throws -> Int {} 

                \(modifierPrefix)struct Foo: WorkflowUpdateDefinition {
                    \(modifierPrefix)typealias Input = String
                    \(modifierPrefix)typealias Output = Int
                    \(modifierPrefix)typealias Workflow = FooWorkflow

                    let _run: @Sendable (Workflow, Input) async throws -> Output
                    init(run: @Sendable @escaping (Workflow, Input) async throws -> Output) {
                        self._run = run
                    }
                    \(modifierPrefix)func run(workflow: Workflow, input: Input) async throws -> Output {
                        try await self._run(workflow, input)
                    }
                }

                static var foo: Foo {
                    Foo(run: {
                            try await $0.foo(input: $1)
                        })
                }
                \(modifierPrefix)func bar(input: Void) throws -> String {
                }

                \(modifierPrefix)struct Bar: WorkflowUpdateDefinition {
                    \(modifierPrefix)typealias Input = Void
                    \(modifierPrefix)typealias Output = String
                    \(modifierPrefix)typealias Workflow = FooWorkflow

                    let _run: @Sendable (Workflow, Input) async throws -> Output
                    init(run: @Sendable @escaping (Workflow, Input) async throws -> Output) {
                        self._run = run
                    }
                    \(modifierPrefix)func run(workflow: Workflow, input: Input) async throws -> Output {
                        try await self._run(workflow, input)
                    }
                    \(modifierPrefix)static var name: String {
                        "MyUpdate"
                    }
                    \(modifierPrefix)static var description: String? {
                        "This is a description."
                    }
                }

                static var bar: Bar {
                    Bar(run: {
                            try await $0.bar(input: $1)
                        })
                }

                static var updates: [any WorkflowUpdateDefinition<FooWorkflow>] {
                    [Self.foo, Self.bar]
                }

                required init(input: Input) {}
            }

            extension FooWorkflow: WorkflowDefinition {
            }
            """,
            removeWhitespace: true
        )
        let (actualOutput, _) = try parse(
            """
            @Workflow
            final class FooWorkflow {
                @WorkflowUpdate
                \(modifierPrefix)func foo(input: String) async throws -> Int {}
                @WorkflowUpdate(name: "MyUpdate", description: "This is a description.")
                \(modifierPrefix)func bar(input: Void) throws -> String {}
            }
            """,
            removeWhitespace: true
        )
        #expect(expectedOutput == actualOutput)
    }

    @Test(
        arguments: ["Input", "Void", "()", "Int", "Double", "String", "Bool"]
    )
    func emptyInitGeneration(type: String) throws {
        let (expectedOutput, _) = try parse(
            """
            final class Foo {
                func run(input: \(type)) async throws {}

                required init(input: Input) {}
            }

            extension Foo: WorkflowDefinition {
            }
            """
        )
        let (actualOutput, _) = try parse(
            """
            @Workflow
            final class Foo {
                func run(input: \(type)) async throws {}
            }
            """
        )
        #expect(expectedOutput == actualOutput)
    }

    @Test
    func typealiasInitGeneration() throws {
        let (expectedOutput, _) = try parse(
            """
            final class Foo {
                typealias Input = String

                func run(input: Input) async throws {}

                required init(input: Input) {}
            }

            extension Foo: WorkflowDefinition {
            }
            """
        )
        let (actualOutput, _) = try parse(
            """
            @Workflow
            final class Foo {
                typealias Input = String

                func run(input: Input) async throws {}
            }
            """
        )
        #expect(expectedOutput == actualOutput)
    }

    @Test
    func structInitGeneration() throws {
        let (expectedOutput, _) = try parse(
            """
            final class Foo {
                struct Input {
                    let test: Int
                }

                func run(input: Input) async throws {}

                required init(input: Input) {}
            }

            extension Foo: WorkflowDefinition {
            }
            """
        )
        let (actualOutput, _) = try parse(
            """
            @Workflow
            final class Foo {
                struct Input {
                    let test: Int
                }

                func run(input: Input) async throws {}
            }
            """
        )
        #expect(expectedOutput == actualOutput)
    }

    @Test
    func existingInit() throws {
        let (expectedOutput, _) = try parse(
            """
            final class Foo {
                init(input: Void) {}

                func run(input: Void) async throws {}
            }

            extension Foo: WorkflowDefinition {
            }
            """
        )
        let (actualOutput, _) = try parse(
            """
            @Workflow
            final class Foo {
                init(input: Void) {}

                func run(input: Void) async throws {}
            }
            """
        )
        #expect(expectedOutput == actualOutput)
    }

    @Test
    func workflowState() throws {
        let (expectedOutput, _) = try parse(
            """
            final class Foo {
                var state {
                    @storageRestrictions(initializes: _state)
                    init(initialValue) {
                        _state = .init(initialValue: initialValue)
                    }
                    get {
                        return _state.value
                    }
                    set {
                        _state.value = newValue
                    }
                }
                
                private nonisolated(unsafe) var _state = _WorkflowState(initialValue: 0)

                func run(input: Void) async throws {
                }

                required init(input: Input) {
                }
            }

            extension Foo: WorkflowDefinition {
            }
            """
        )
        let (actualOutput, _) = try parse(
            """
            @Workflow
            final class Foo {
                var state = 0

                func run(input: Void) async throws {}
            }
            """
        )
        #expect(expectedOutput == actualOutput)
    }

    @Test
    func workflowStateCustomName() throws {
        let (expectedOutput, _) = try parse(
            """
            final class Foo {
                var state {
                    @storageRestrictions(initializes: _state)
                    init(initialValue) {
                        _state = .init(initialValue: initialValue)
                    }
                    get {
                        return _state.value
                    }
                    set {
                        _state.value = newValue
                    }
                }
                
                private nonisolated(unsafe) var _state = _WorkflowState(initialValue: 0)

                func run(input: Void) async throws {
                }

                required init(input: Input) {
                }
            }

            extension Foo: WorkflowDefinition {
                static var name: String {
                    "CustomName"
                }
            }
            """
        )
        let (actualOutput, _) = try parse(
            """
            @Workflow(name: "CustomName")
            final class Foo {
                var state = 0

                func run(input: Void) async throws {}
            }
            """
        )
        #expect(expectedOutput == actualOutput)
    }
}
