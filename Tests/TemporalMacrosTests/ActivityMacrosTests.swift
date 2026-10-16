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
                        let container: Foo
                        func run(input: Int) async throws -> Int { return try await _activityResult(self.container.bar(input: input)) }
                    }
                    var bar: Bar { return .init(container: self.container) }
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

    @Test
    func argumentLabels() throws {
        let (expectedOutput, _) = try parse(
            """
            struct Foo {
                func unlabeled(_ input: Int) async throws -> Int { return input }
                func labeled(value: Int) async -> Int { return value }
                static func throwing() throws {}
            }

            extension Foo: ActivityContainer {
                struct Activities {
                    let container: Foo
                    struct Unlabeled: ActivityDefinition {
                        static var name: String { "Unlabeled" }
                        let container: Foo
                        func run(input: Int) async throws -> Int { return try await _activityResult(self.container.unlabeled(input)) }
                    }
                    var unlabeled: Unlabeled { return .init(container: self.container) }
                    struct Labeled: ActivityDefinition {
                        static var name: String { "Labeled" }
                        let container: Foo
                        func run(input: Int) async throws -> Int { return try await _activityResult(self.container.labeled(value: input)) }
                    }
                    var labeled: Labeled { return .init(container: self.container) }
                    struct Throwing: ActivityDefinition {
                        static var name: String { "Throwing" }
                        func run(input: Void) async throws -> Void { return try await _activityResult(Foo.throwing()) }
                    }
                    var throwing: Throwing { return .init() }
                }
                var activities: Activities { return .init(container: self) }
                var allActivities: [any ActivityDefinition] {
                    return [self.activities.unlabeled, self.activities.labeled, self.activities.throwing]
                }
            }
            """
        )
        let (actualOutput, diagnostics) = try parse(
            """
            @ActivityContainer
            struct Foo {
                @Activity
                func unlabeled(_ input: Int) async throws -> Int { return input }
                @Activity
                func labeled(value: Int) async -> Int { return value }
                @Activity
                static func throwing() throws {}
            }
            """
        )

        #expect(expectedOutput == actualOutput)
        #expect(diagnostics.isEmpty)
    }

    @Test(arguments: ["public", "package", "fileprivate", "internal", "private"])
    func accessModifier(modifier: String) throws {
        let declarationModifier = modifier == "private" ? "fileprivate" : modifier  // private is not allowed for @ActivityContainer
        let activityModifier = modifier

        let (expectedOutput, _) = try parse(
            """
            \(declarationModifier) struct Foo {
                func bar(input: Int) -> Int { return input }
                \(activityModifier) func bar2(input: Int) -> Int { return input }
            }

            extension Foo: ActivityContainer {
                \(declarationModifier) struct Activities {
                    let container: Foo
                    struct Bar: ActivityDefinition {
                        static var name: String { "Bar" }
                        let container: Foo
                        func run(input: Int) async throws -> Int { return try await _activityResult(self.container.bar(input: input)) }
                    }
                    var bar: Bar { return .init(container: self.container) }
                    \(activityModifier) struct Bar2: ActivityDefinition {
                        \(activityModifier) static var name: String { "Bar2" }
                        let container: Foo
                        \(activityModifier) func run(input: Int) async throws -> Int { return try await _activityResult(self.container.bar2(input: input)) }
                    }
                    \(activityModifier) var bar2: Bar2 { return .init(container: self.container) }
                }
                \(declarationModifier) var activities: Activities { return .init(container: self) }
                \(declarationModifier) var allActivities: [any ActivityDefinition] { return [self.activities.bar, self.activities.bar2] }
            }
            """
        )
        let (actualOutput, diagnostics) = try parse(
            """
            @ActivityContainer
            \(declarationModifier) struct Foo {
                @Activity
                func bar(input: Int) -> Int {  return input }

                @Activity
                \(activityModifier) func bar2(input: Int) -> Int { return input }
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
                \(rawResultingModifier)struct Activities {
                    let container: Foo
                    struct Bar: ActivityDefinition {
                        static var name: String { "Bar" }
                        let container: Foo
                        func run(input: Int) async throws -> Int { return try await _activityResult(self.container.bar(input: input)) }
                    }
                    var bar: Bar { return .init(container: self.container) }
                }
                \(rawResultingModifier)var activities: Activities { return .init(container: self) }
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
                        func run(input: Int) async throws -> Int { return try await _activityResult(Foo.bar(input: input)) }
                    }
                    var bar: Bar { return .init() }
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
                        func run(input: Void) async throws -> Int { return try await _activityResult(Foo.bar()) }
                    }
                    var bar: Bar { return .init() }
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
                        func run(input: Void) async throws -> Void { return try await _activityResult(Foo.bar()) }
                    }
                    var bar: Bar { return .init() }
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
                        func run(input: Void) async throws -> Void { return try await _activityResult(Foo.bar()) }
                    }
                    var bar: Bar { return .init() }
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
                        let container: Namespace.Foo
                        func run(input: Int) async throws -> Int { return try await _activityResult(self.container.bar(input: input)) }
                    }
                    var bar: Bar { return .init(container: self.container) }
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

    @Test
    func dynamicActivity() throws {
        let (expectedOutput, _) = try parse(
            """
            struct Foo {
                static func handle(input: [TemporalRawValue]) -> TemporalRawValue { fatalError() }
            }

            extension Foo: ActivityContainer {
                struct Activities {
                    struct Handle: ActivityDefinition {
                        static var isDynamic: Bool { true }
                        func run(input: [TemporalRawValue]) async throws -> TemporalRawValue { return try await _activityResult(Foo.handle(input: input)) }
                    }
                    var handle: Handle { return .init() }
                }
                var activities: Activities { return .init() }
                var allActivities: [any ActivityDefinition] { return [self.activities.handle] }
            }
            """
        )
        let (actualOutput, diagnostics) = try parse(
            """
            @ActivityContainer
            struct Foo {
                @Activity(dynamic: true)
                static func handle(input: [TemporalRawValue]) -> TemporalRawValue { fatalError() }
            }
            """
        )

        #expect(expectedOutput == actualOutput)
        #expect(diagnostics.isEmpty)
    }

    @Test
    func dynamicActivityWithCustomNameProducesError() throws {
        let (_, diagnostics) = try parse(
            """
            @ActivityContainer
            struct Foo {
                @Activity(name: "CustomName", dynamic: true)
                static func handle(input: [TemporalRawValue]) -> TemporalRawValue { fatalError() }
            }
            """
        )

        #expect(diagnostics.count == 1)
        #expect(
            diagnostics.first?.message
                == "A dynamic activity cannot have a custom name. Dynamic activities handle all unregistered activity types."
        )
    }
}
