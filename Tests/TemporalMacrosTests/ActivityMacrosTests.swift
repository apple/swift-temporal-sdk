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

import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import Testing

@Suite(.tags(.macroTests))
struct ActivityMacrosTests {
    @Test
    func simple() throws {
        let (expectedOutput, _) = try parse(
            """
            class Foo {
                func bar(input: Int) -> Int { return input }
            }

            extension Foo: ActivityContainer {
                struct Activities {
                    let container: Foo
                    struct Bar: ActivityDefinition {
                        static var name: String { "Bar" }
                        var _run: @Sendable (Int) async throws -> Int
                        init(run: @escaping @Sendable (Int) async throws -> Int) { self._run = run }
                        func run(input: Int) async throws -> Int { return try await self._run(input) }
                    }
                    var bar: Bar { return .init(run: self.container.bar) }
                }
                var activities: Activities { return .init(container: self) }
                var allActivities: [any ActivityDefinition] { return [self.activities.bar] }
            }
            """
        )
        let (actualOutput, diagnostics) = try parse(
            """
            @ActivityContainer
            class Foo {
                @Activity
                func bar(input: Int) -> Int { return input }
            }
            """
        )

        #expect(expectedOutput == actualOutput)
        #expect(diagnostics.isEmpty)
    }

    @Test(arguments: ["public", "package", "fileprivate", "internal"])
    func accessModifier(modifier: String) throws {
        let (expectedOutput, _) = try parse(
            """
            \(modifier) struct Foo {
                func bar(input: Int) -> Int { return input }
                \(modifier) func bar2(input: Int) -> Int { return input }
            }

            extension Foo: ActivityContainer {
                struct Activities {
                    let container: Foo
                    struct Bar: ActivityDefinition {
                        static var name: String { "Bar" }
                        var _run: @Sendable (Int) async throws -> Int
                        init(run: @escaping @Sendable (Int) async throws -> Int) { self._run = run }
                        func run(input: Int) async throws -> Int { return try await self._run(input) }
                    }
                    var bar: Bar { return .init(run: self.container.bar) }
                    struct Bar2: ActivityDefinition {
                        static var name: String { "Bar2" }
                        var _run: @Sendable (Int) async throws -> Int
                        init(run: @escaping @Sendable (Int) async throws -> Int) { self._run = run }
                        func run(input: Int) async throws -> Int { return try await self._run(input) }
                    }
                    var bar2: Bar2 { return .init(run: self.container.bar2) }
                }
                var activities: Activities { return .init(container: self) }
                \(modifier) var allActivities: [any ActivityDefinition] { return [self.activities.bar, self.activities.bar2] }
            }
            """
        )
        let (actualOutput, diagnostics) = try parse(
            """
            @ActivityContainer
            \(modifier) struct Foo {
                @Activity
                func bar(input: Int) -> Int {  return input }

                @Activity
                \(modifier) func bar2(input: Int) -> Int { return input }
            }
            """
        )

        #expect(expectedOutput == actualOutput)
        #expect(diagnostics.isEmpty)
    }

    @Test(arguments: [
        ("final", nil),
        ("public final", "public"),
        ("final public", "public"),
    ])
    func ignoredModifiers(modifierList: String, result: String?) throws {
        let rawResultingModifier = result.map { $0 + " " } ?? ""

        let (expectedOutput, _) = try parse(
            """
            \(modifierList) class Foo {
                func bar(input: Int) -> Int { return input }
            }

            extension Foo: ActivityContainer {
                struct Activities {
                    let container: Foo
                    struct Bar: ActivityDefinition {
                        static var name: String { "Bar" }
                        var _run: @Sendable (Int) async throws -> Int
                        init(run: @escaping @Sendable (Int) async throws -> Int) { self._run = run }
                        func run(input: Int) async throws -> Int { return try await self._run(input) }
                    }
                    var bar: Bar { return .init(run: self.container.bar) }
                }
                var activities: Activities { return .init(container: self) }
                \(rawResultingModifier)var allActivities: [any ActivityDefinition] { return [self.activities.bar] }
            }
            """
        )
        let (actualOutput, diagnostics) = try parse(
            """
            @ActivityContainer
            \(modifierList) class Foo {
                @Activity
                func bar(input: Int) -> Int { return input }
            }
            """
        )

        #expect(expectedOutput == actualOutput)
        #expect(diagnostics.isEmpty)
    }

    @Test
    func staticMethod() throws {
        let (expectedOutput, _) = try parse(
            """
            struct Foo {
                static func bar(input: Int) -> Int { return input }
            }

            extension Foo: ActivityContainer {
                struct Activities {
                    struct Bar: ActivityDefinition {
                        static var name: String { "Bar" }
                        var _run: @Sendable (Int) async throws -> Int
                        init(run: @escaping @Sendable (Int) async throws -> Int) { self._run = run }
                        func run(input: Int) async throws -> Int { return try await self._run(input) }
                    }
                    var bar: Bar { return .init(run: Foo.bar) }
                }
                var activities: Activities { return .init() }
                var allActivities: [any ActivityDefinition] { return [self.activities.bar] }
            }
            """
        )
        let (actualOutput, diagnostics) = try parse(
            """
            @ActivityContainer
            struct Foo {
                @Activity
                static func bar(input: Int) -> Int { return input }
            }
            """
        )

        #expect(expectedOutput == actualOutput)
        #expect(diagnostics.isEmpty)
    }

    @Test
    func noInput() throws {
        let (expectedOutput, _) = try parse(
            """
            struct Foo {
                static func bar() -> Int { return input }
            }

            extension Foo: ActivityContainer {
                struct Activities {
                    struct Bar: ActivityDefinition {
                        static var name: String { "Bar" }
                        var _run: @Sendable () async throws -> Int
                        init(run: @escaping @Sendable () async throws -> Int) { self._run = run }
                        func run(input: Void) async throws -> Int { return try await self._run() }
                    }
                    var bar: Bar { return .init(run: Foo.bar) }
                }
                var activities: Activities { return .init() }
                var allActivities: [any ActivityDefinition] { return [self.activities.bar] }
            }
            """
        )
        let (actualOutput, diagnostics) = try parse(
            """
            @ActivityContainer
            struct Foo {
                @Activity
                static func bar() -> Int { return input }
            }
            """
        )

        #expect(expectedOutput == actualOutput)
        #expect(diagnostics.isEmpty)
    }

    @Test
    func noOutput() throws {
        let (expectedOutput, _) = try parse(
            """
            struct Foo {
                static func bar() { }
            }

            extension Foo: ActivityContainer {
                struct Activities {
                    struct Bar: ActivityDefinition {
                        static var name: String { "Bar" }
                        var _run: @Sendable () async throws -> Void
                        init(run: @escaping @Sendable () async throws -> Void) { self._run = run }
                        func run(input: Void) async throws -> Void { return try await self._run() }
                    }
                    var bar: Bar { return .init(run: Foo.bar) }
                }
                var activities: Activities { return .init() }
                var allActivities: [any ActivityDefinition] { return [self.activities.bar] }
            }
            """
        )
        let (actualOutput, diagnostics) = try parse(
            """
            @ActivityContainer
            struct Foo {
                @Activity
                static func bar() { }
            }
            """
        )

        #expect(expectedOutput == actualOutput)
        #expect(diagnostics.isEmpty)
    }

    @Test
    func customActivityName() throws {
        let (expectedOutput, _) = try parse(
            """
            struct Foo {
                static func bar() { }
            }

            extension Foo: ActivityContainer {
                struct Activities {
                    struct Bar: ActivityDefinition {
                        static var name: String { "FooActivity" }
                        var _run: @Sendable () async throws -> Void
                        init(run: @escaping @Sendable () async throws -> Void) { self._run = run }
                        func run(input: Void) async throws -> Void { return try await self._run() }
                    }
                    var bar: Bar { return .init(run: Foo.bar) }
                }
                var activities: Activities { return .init() }
                var allActivities: [any ActivityDefinition] { return [self.activities.bar] }
            }
            """
        )
        let (actualOutput, diagnostics) = try parse(
            """
            @ActivityContainer
            struct Foo {
                @Activity(name: "FooActivity")
                static func bar() { }
            }
            """
        )

        #expect(expectedOutput == actualOutput)
        #expect(diagnostics.isEmpty)
    }

    @Test
    func wrappedInNamespaceEnum() throws {
        let (expectedOutput, _) = try parse(
            """
            enum Namespace {
                struct Foo {
                    func bar(input: Int) -> Int { return input }
                }
            }

            extension Namespace.Foo: ActivityContainer {
                struct Activities {
                    let container: Namespace.Foo
                    struct Bar: ActivityDefinition {
                        static var name: String { "Bar" }
                        var _run: @Sendable (Int) async throws -> Int
                        init(run: @escaping @Sendable (Int) async throws -> Int) { self._run = run }
                        func run(input: Int) async throws -> Int { return try await self._run(input) }
                    }
                    var bar: Bar { return .init(run: self.container.bar) }
                }
                var activities: Activities { return .init(container: self) }
                var allActivities: [any ActivityDefinition] { return [self.activities.bar] }
            }
            """
        )
        let (actualOutput, diagnostics) = try parse(
            """
            enum Namespace {
                @ActivityContainer
                struct Foo {
                    @Activity
                    func bar(input: Int) -> Int { return input }
                }
            }
            """
        )

        #expect(expectedOutput == actualOutput)
        #expect(diagnostics.isEmpty)
    }
}
