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

/// Defines a Temporal activity function.
///
/// The `@Activity` macro automatically generates the necessary implementation code to register a
/// function as a Temporal activity. When applied to a function, it creates an activity definition that can be executed by Temporal workers.
///
/// ## Usage
///
/// ```swift
/// struct GreetingActivity {
///     @Activity
///     func greet(name: String) async throws -> String {
///         return "Hello, \(name)!"
///     }
/// }
/// ```
///
/// ## Dynamic Activities
///
/// Mark an activity as dynamic to create a catch-all handler for unregistered activity types:
///
/// ```swift
/// struct MyDynamicActivity {
///     @Activity(dynamic: true)
///     func handle(input: [TemporalRawValue]) async throws -> TemporalRawValue {
///         let activityType = ActivityExecutionContext.current!.info.activityType
///         // Handle based on activity type...
///     }
/// }
/// ```
///
/// - Parameters:
///   - name: The name of the activity. If not provided, defaults to the function name.
///   - dynamic: Whether this activity is dynamic. A dynamic activity cannot have a custom name.
@attached(peer)
public macro Activity(name: String? = nil, dynamic: Bool = false) =
    #externalMacro(
        module: "TemporalMacros",
        type: "ActivityMacro"
    )

/// Generates an extension conforming to ``ActivityContainer`` for a type containing activity functions.
///
/// The `@ActivityContainer` macro analyzes a type for functions marked with `@Activity` and automatically
/// generates the necessary ``ActivityContainer`` conformance. This allows all activities within the container
/// to be registered with a Temporal worker.
///
/// ```swift
/// @ActivityContainer
/// struct GreetingsContainer {
///     @Activity
///     func greet(name: String) async throws -> String {
///         return "Hello, \(name)!"
///     }
///
///     @Activity
///     func bavarianGreeting(name: String) async throws -> String {
///         return "Servus, \(name)!"
///     }
/// }
/// ```
@attached(extension, conformances: ActivityContainer, names: arbitrary)
public macro ActivityContainer() = #externalMacro(module: "TemporalMacros", type: "ActivityContainerMacro")
