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

import SwiftDiagnostics
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
            struct Foo {

                init(input: Input) {}
            }

            extension Foo: WorkflowDefinition {
            }
            """
        )
        let (actualOutput, _) = try parse(
            """
            @Workflow
            struct Foo {}
            """
        )
        #expect(expectedOutput == actualOutput)
    }

    @Test(arguments: ["public", "package", "internal", "fileprivate"])
    func accessModifier(modifier: String) throws {
        let (expectedOutput, _) = try parse(
            """
            \(modifier) struct Foo {
                func fooSignal(input: String) async throws {}

                struct FooSignal: WorkflowSignalDefinition {
                    typealias Input = String
                    typealias Workflow = Foo

                    let _run: @Sendable (Workflow, WorkflowContext<Workflow>, Input) async throws -> Void
                    init(run: @Sendable @escaping (Workflow, WorkflowContext<Workflow>, Input) async throws -> Void) {
                        self._run = run
                    }
                    func run(workflow: Workflow, context: WorkflowContext<Workflow>, input: Input) async throws {
                        try await self._run(workflow, context, input)
                    }
                }

                static var fooSignal: FooSignal {
                    FooSignal(run: { workflow, _, input in
                            try await workflow.fooSignal(input: input)
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

                    let _run: @Sendable (Workflow, WorkflowContext<Workflow>, Input) async throws -> Output
                    init(run: @Sendable @escaping (Workflow, WorkflowContext<Workflow>, Input) async throws -> Output) {
                        self._run = run
                    }
                    func run(workflow: Workflow, context: WorkflowContext<Workflow>, input: Input) async throws -> Output{
                        try await self._run(workflow, context, input)
                    }
                }

                static var fooUpdate: FooUpdate {
                    FooUpdate(run: { workflow, _, input in
                            try await workflow.fooUpdate(input: input)
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

                \(modifier) init(input: Input) {}
            }

            extension Foo: WorkflowDefinition {
                \(modifier) static var name: String { "CustomName" }
            }
            """,
            removeWhitespace: true
        )
        let (actualOutput, _) = try parse(
            """
            @Workflow(name: "CustomName")
            \(modifier) struct Foo {
                @WorkflowSignal
                func fooSignal(input: String) async throws {}
                @WorkflowQuery
                func fooQuery(input: String) throws -> String {}
                @WorkflowUpdate
                func fooUpdate(input: String) async throws -> Int {}
            }
            """,
            removeWhitespace: true
        )
        #expect(expectedOutput == actualOutput)
    }

    @Test
    func namedWorkflow() throws {
        let (expectedOutput, _) = try parse(
            """
            struct Foo {

                init(input: Input) {}
            }

            extension Foo: WorkflowDefinition {
                static var name: String { "CustomName" }
            }
            """
        )
        let (actualOutput, _) = try parse(
            """
            @Workflow(name: "CustomName")
            struct Foo {}
            """
        )
        #expect(expectedOutput == actualOutput)
    }

    @Test(arguments: [nil, "public", "package", "internal", "fileprivate", "private"])
    func signal(modifier: String?) throws {
        let modifierPrefix = modifier.map { "\($0) " } ?? ""

        let (expectedOutput, _) = try parse(
            """
            struct FooWorkflow {
                \(modifierPrefix)func foo(input: String) async throws {}

                \(modifierPrefix)struct Foo: WorkflowSignalDefinition {
                    \(modifierPrefix)typealias Input = String
                    \(modifierPrefix)typealias Workflow = FooWorkflow

                    let _run: @Sendable (Workflow, WorkflowContext<Workflow>, Input) async throws -> Void
                    init(run: @Sendable @escaping (Workflow, WorkflowContext<Workflow>, Input) async throws -> Void) {
                        self._run = run
                    }
                    \(modifierPrefix)func run(workflow: Workflow, context: WorkflowContext<Workflow>, input: Input) async throws {
                        try await self._run(workflow, context, input)
                    }
                }

                static var foo: Foo {
                    Foo(run: { workflow, _, input in
                            try await workflow.foo(input: input)
                        })
                }
                \(modifierPrefix)func bar(input: Void) async throws {
                }

                \(modifierPrefix)struct Bar: WorkflowSignalDefinition {
                    \(modifierPrefix)typealias Input = Void
                    \(modifierPrefix)typealias Workflow = FooWorkflow

                    let _run: @Sendable (Workflow, WorkflowContext<Workflow>, Input) async throws -> Void
                    init(run: @Sendable @escaping (Workflow, WorkflowContext<Workflow>, Input) async throws -> Void) {
                        self._run = run
                    }
                    \(modifierPrefix)func run(workflow: Workflow, context: WorkflowContext<Workflow>, input: Input) async throws {
                        try await self._run(workflow, context, input)
                    }
                    \(modifierPrefix)static var name: String {
                        "MySignal"
                    }
                    \(modifierPrefix)static var description: String? {
                        "This is a description."
                    }
                }

                static var bar: Bar {
                    Bar(run: { workflow, _, input in
                            try await workflow.bar(input: input)
                        })
                }

                static var signals: [any WorkflowSignalDefinition<FooWorkflow>] {
                    [Self.foo, Self.bar]
                }

                init(input: Input) {}
            }

            extension FooWorkflow: WorkflowDefinition {
            }
            """,
            removeWhitespace: true
        )
        let (actualOutput, _) = try parse(
            """
            @Workflow
            struct FooWorkflow {
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
            struct FooWorkflow {
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

                init(input: Input) {}
            }

            extension FooWorkflow: WorkflowDefinition {
            }
            """,
            removeWhitespace: true
        )
        let (actualOutput, _) = try parse(
            """
            @Workflow
            struct FooWorkflow {
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
            struct FooWorkflow {
                \(modifierPrefix)func foo(input: String) async throws -> Int {}

                \(modifierPrefix)struct Foo: WorkflowUpdateDefinition {
                    \(modifierPrefix)typealias Input = String
                    \(modifierPrefix)typealias Output = Int
                    \(modifierPrefix)typealias Workflow = FooWorkflow

                    let _run: @Sendable (Workflow, WorkflowContext<Workflow>, Input) async throws -> Output
                    init(run: @Sendable @escaping (Workflow, WorkflowContext<Workflow>, Input) async throws -> Output) {
                        self._run = run
                    }
                    \(modifierPrefix)func run(workflow: Workflow, context: WorkflowContext<Workflow>, input: Input) async throws -> Output{
                        try await self._run(workflow, context, input)
                    }
                }

                static var foo: Foo {
                    Foo(run: { workflow, _, input in
                            try await workflow.foo(input: input)
                        })
                }
                \(modifierPrefix)func bar(input: Void) throws -> String {
                }

                \(modifierPrefix)struct Bar: WorkflowUpdateDefinition {
                    \(modifierPrefix)typealias Input = Void
                    \(modifierPrefix)typealias Output = String
                    \(modifierPrefix)typealias Workflow = FooWorkflow

                    let _run: @Sendable (Workflow, WorkflowContext<Workflow>, Input) async throws -> Output
                    init(run: @Sendable @escaping (Workflow, WorkflowContext<Workflow>, Input) async throws -> Output) {
                        self._run = run
                    }
                    \(modifierPrefix)func run(workflow: Workflow, context: WorkflowContext<Workflow>, input: Input) async throws -> Output{
                        try await self._run(workflow, context, input)
                    }
                    \(modifierPrefix)static var name: String {
                        "MyUpdate"
                    }
                    \(modifierPrefix)static var description: String? {
                        "This is a description."
                    }
                }

                static var bar: Bar {
                    Bar(run: { workflow, _, input in
                            try await workflow.bar(input: input)
                        })
                }

                static var updates: [any WorkflowUpdateDefinition<FooWorkflow>] {
                    [Self.foo, Self.bar]
                }

                init(input: Input) {}
            }

            extension FooWorkflow: WorkflowDefinition {
            }
            """,
            removeWhitespace: true
        )
        let (actualOutput, _) = try parse(
            """
            @Workflow
            struct FooWorkflow {
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
            struct Foo {
                func run(input: \(type)) async throws {}

                init(input: Input) {}
            }

            extension Foo: WorkflowDefinition {
            }
            """
        )
        let (actualOutput, _) = try parse(
            """
            @Workflow
            struct Foo {
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
            struct Foo {
                typealias Input = String

                func run(input: Input) async throws {}

                init(input: Input) {}
            }

            extension Foo: WorkflowDefinition {
            }
            """
        )
        let (actualOutput, _) = try parse(
            """
            @Workflow
            struct Foo {
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
            struct Foo {
                struct Input {
                    let test: Int
                }

                func run(input: Input) async throws {}

                init(input: Input) {}
            }

            extension Foo: WorkflowDefinition {
            }
            """
        )
        let (actualOutput, _) = try parse(
            """
            @Workflow
            struct Foo {
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
            struct Foo {
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
            struct Foo {
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
            struct Foo {
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

                init(input: Input) {
                }
            }

            extension Foo: WorkflowDefinition {
            }
            """
        )
        let (actualOutput, _) = try parse(
            """
            @Workflow
            struct Foo {
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
            struct Foo {
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

                init(input: Input) {
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
            struct Foo {
                var state = 0

                func run(input: Void) async throws {}
            }
            """
        )
        #expect(expectedOutput == actualOutput)
    }

    @Test
    func signalWithUnfinishedPolicy() throws {
        let (expectedOutput, _) = try parse(
            """
            struct FooWorkflow {
                func foo(input: String) async throws {}

                struct Foo: WorkflowSignalDefinition {
                    typealias Input = String
                    typealias Workflow = FooWorkflow

                    let _run: @Sendable (Workflow, WorkflowContext<Workflow>, Input) async throws -> Void
                    init(run: @Sendable @escaping (Workflow, WorkflowContext<Workflow>, Input) async throws -> Void) {
                        self._run = run
                    }
                    func run(workflow: Workflow, context: WorkflowContext<Workflow>, input: Input) async throws {
                        try await self._run(workflow, context, input)
                    }

                    static var unfinishedPolicy: HandlerUnfinishedPolicy { .abandon }
                }

                static var foo: Foo {
                    Foo(run: { workflow, _, input in
                            try await workflow.foo(input: input)
                        })
                }

                static var signals: [any WorkflowSignalDefinition<FooWorkflow>] {
                    [Self.foo]
                }

                init(input: Input) {}
            }

            extension FooWorkflow: WorkflowDefinition {
            }
            """,
            removeWhitespace: true
        )
        let (actualOutput, _) = try parse(
            """
            @Workflow
            struct FooWorkflow {
                @WorkflowSignal(unfinishedPolicy: .abandon)
                func foo(input: String) async throws {}
            }
            """,
            removeWhitespace: true
        )
        #expect(expectedOutput == actualOutput)
    }

    @Test
    func updateWithUnfinishedPolicy() throws {
        let (expectedOutput, _) = try parse(
            """
            struct FooWorkflow {
                func foo(input: String) async throws -> Int {}

                struct Foo: WorkflowUpdateDefinition {
                    typealias Input = String
                    typealias Output = Int
                    typealias Workflow = FooWorkflow

                    let _run: @Sendable (Workflow, WorkflowContext<Workflow>, Input) async throws -> Output
                    init(run: @Sendable @escaping (Workflow, WorkflowContext<Workflow>, Input) async throws -> Output) {
                        self._run = run
                    }
                    func run(workflow: Workflow, context: WorkflowContext<Workflow>, input: Input) async throws -> Output{
                        try await self._run(workflow, context, input)
                    }

                    static var unfinishedPolicy: HandlerUnfinishedPolicy { .abandon }
                }

                static var foo: Foo {
                    Foo(run: { workflow, _, input in
                            try await workflow.foo(input: input)
                        })
                }

                static var updates: [any WorkflowUpdateDefinition<FooWorkflow>] {
                    [Self.foo]
                }

                init(input: Input) {}
            }

            extension FooWorkflow: WorkflowDefinition {
            }
            """,
            removeWhitespace: true
        )
        let (actualOutput, _) = try parse(
            """
            @Workflow
            struct FooWorkflow {
                @WorkflowUpdate(unfinishedPolicy: .abandon)
                func foo(input: String) async throws -> Int {}
            }
            """,
            removeWhitespace: true
        )
        #expect(expectedOutput == actualOutput)
    }

    @Test(arguments: [nil, "public", "package", "internal", "fileprivate", "private"])
    func updateWithValidator(modifier: String?) throws {
        let modifierPrefix = modifier.map { "\($0) " } ?? ""

        let (expectedOutput, _) = try parse(
            """
            struct FooWorkflow {
                \(modifierPrefix)func foo(input: String) async throws -> Int {}

                \(modifierPrefix)struct Foo: WorkflowUpdateDefinition {
                    \(modifierPrefix)typealias Input = String
                    \(modifierPrefix)typealias Output = Int
                    \(modifierPrefix)typealias Workflow = FooWorkflow

                    let _run: @Sendable (Workflow, WorkflowContext<Workflow>, Input) async throws -> Output
                    init(run: @Sendable @escaping (Workflow, WorkflowContext<Workflow>, Input) async throws -> Output, validate: @Sendable @escaping (Workflow, Input) throws -> Void) {
                        self._run = run
                        self._validate = validate
                    }
                    \(modifierPrefix)func run(workflow: Workflow, context: WorkflowContext<Workflow>, input: Input) async throws -> Output{
                        try await self._run(workflow, context, input)
                    }

                    let _validate: @Sendable (Workflow, Input) throws -> Void
                    \(modifierPrefix)func validateInput(workflow: Workflow, _ input: Input) throws {
                        try self._validate(workflow, input)
                    }
                }

                static var foo: Foo {
                    Foo(run: { workflow, _, input in
                            try await workflow.foo(input: input)
                        }, validate: {
                            try $0.validateFoo(input: $1)
                        })
                }

                func validateFoo(input: String) throws {}

                static var updates: [any WorkflowUpdateDefinition<FooWorkflow>] {
                    [Self.foo]
                }

                init(input: Input) {}
            }

            extension FooWorkflow: WorkflowDefinition {
            }
            """,
            removeWhitespace: true
        )
        let (actualOutput, _) = try parse(
            """
            @Workflow
            struct FooWorkflow {
                @WorkflowUpdate(validator: "validateFoo")
                \(modifierPrefix)func foo(input: String) async throws -> Int {}

                func validateFoo(input: String) throws {}
            }
            """,
            removeWhitespace: true
        )
        #expect(expectedOutput == actualOutput)
    }

    // MARK: - Validator Diagnostic Tests

    @Test
    func validatorGeneratesCorrectCall() throws {
        let (_, diagnostics) = try parse(
            """
            @Workflow
            struct FooWorkflow {
                @WorkflowUpdate(validator: "validateFoo")
                func foo(input: String) async throws -> Int {}

                func validateFoo(input: String) throws {}
            }
            """,
            removeWhitespace: true
        )
        #expect(diagnostics.isEmpty)
    }

    @Test
    func updateWithoutValidatorHasNoValidateMethod() throws {
        let (output, diagnostics) = try parse(
            """
            @Workflow
            struct FooWorkflow {
                @WorkflowUpdate
                func foo(input: String) async throws -> Int {}
            }
            """,
            removeWhitespace: true
        )
        #expect(diagnostics.isEmpty)
        #expect(!output.contains("validateInput"))
        #expect(!output.contains("_validate"))
    }

    @Test
    func updateWithValidatorGeneratesValidateInput() throws {
        let (output, diagnostics) = try parse(
            """
            @Workflow
            struct FooWorkflow {
                @WorkflowUpdate(validator: "validateFoo")
                func foo(input: String) async throws -> Int {}

                func validateFoo(input: String) throws {}
            }
            """,
            removeWhitespace: true
        )
        #expect(diagnostics.isEmpty)
        #expect(output.contains("validateInput"))
        #expect(output.contains("_validate"))
        #expect(output.contains("validateFoo"))
    }

    @Test
    func validatorNotFound() throws {
        let (_, diagnostics) = try parse(
            """
            @Workflow
            struct FooWorkflow {
                @WorkflowUpdate(validator: "doesNotExist")
                func foo(input: String) async throws -> Int {}
            }
            """
        )
        #expect(diagnostics.count == 1)
        #expect(diagnostics.first?.message == "Validator method 'doesNotExist' not found in workflow")
        // Diagnostic should be on the @WorkflowUpdate attribute
        #expect(diagnostics.first?.node.description.contains("WorkflowUpdate") == true)
    }

    @Test
    func validatorIsAsync() throws {
        let (_, diagnostics) = try parse(
            """
            @Workflow
            struct FooWorkflow {
                @WorkflowUpdate(validator: "validateFoo")
                func foo(input: String) async throws -> Int {}

                func validateFoo(input: String) async throws {}
            }
            """
        )
        #expect(diagnostics.count == 1)
        #expect(diagnostics.first?.message == "Validator method 'validateFoo' must not be async")
        // Diagnostic should be on the validator function declaration
        #expect(diagnostics.first?.node.description.contains("validateFoo") == true)
    }

    @Test
    func validatorReturnsValue() throws {
        let (_, diagnostics) = try parse(
            """
            @Workflow
            struct FooWorkflow {
                @WorkflowUpdate(validator: "validateFoo")
                func foo(input: String) async throws -> Int {}

                func validateFoo(input: String) throws -> Bool {}
            }
            """
        )
        #expect(diagnostics.count == 1)
        #expect(diagnostics.first?.message == "Validator method 'validateFoo' must return Void")
        // Diagnostic should be on the return clause
        #expect(diagnostics.first?.node.description.contains("Bool") == true)
    }

    @Test
    func validatorWrongParameterCount() throws {
        let (_, diagnostics) = try parse(
            """
            @Workflow
            struct FooWorkflow {
                @WorkflowUpdate(validator: "validateFoo")
                func foo(input: String) async throws -> Int {}

                func validateFoo(input: String, extra: Int) throws {}
            }
            """
        )
        #expect(diagnostics.count == 1)
        #expect(
            diagnostics.first?.message
                == "Validator method 'validateFoo' must have exactly one parameter matching the update input"
        )
        // Diagnostic should be on the parameter clause
        #expect(diagnostics.first?.node.description.contains("extra") == true)
    }

    @Test
    func validatorWrongParameterName() throws {
        let (_, diagnostics) = try parse(
            """
            @Workflow
            struct FooWorkflow {
                @WorkflowUpdate(validator: "validateFoo")
                func foo(input: String) async throws -> Int {}

                func validateFoo(value: String) throws {}
            }
            """
        )
        #expect(diagnostics.count == 1)
        #expect(diagnostics.first?.message == "Validator method 'validateFoo' parameter must be called 'input'")
        // Diagnostic should be on the parameter
        #expect(diagnostics.first?.node.description.contains("value") == true)
    }

    @Test
    func validatorWrongInputType() throws {
        let (_, diagnostics) = try parse(
            """
            @Workflow
            struct FooWorkflow {
                @WorkflowUpdate(validator: "validateFoo")
                func foo(input: String) async throws -> Int {}

                func validateFoo(input: Int) throws {}
            }
            """
        )
        #expect(diagnostics.count == 1)
        #expect(
            diagnostics.first?.message
                == "Validator method 'validateFoo' input type 'Int' does not match update input type 'String'"
        )
        // Diagnostic should be on the parameter type
        #expect(diagnostics.first?.node.description.contains("Int") == true)
    }
}
