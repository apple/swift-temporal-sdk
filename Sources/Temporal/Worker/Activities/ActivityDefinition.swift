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

/// A protocol defining a Temporal activity implementation.
///
/// Activities represent units of work that are executed outside of the workflow context.
/// They are typically used for operations that interact with external systems, perform I/O operations,
/// or execute non-deterministic code.
///
/// ## Usage
///
/// ### Manual Implementation
///
/// ```swift
/// struct GreetingActivity: ActivityDefinition {
///     static let name = "greeting"
///
///     func run(input: String) async throws -> String {
///         return "Hello, \(input)!"
///     }
/// }
/// ```
///
/// ### Using the @Activity Macro
///
/// For simplified activity creation, use the `@Activity` macro which automatically generates the required boilerplate:
///
/// ```swift
/// struct GreetingActivity {
///     @Activity
///     func run(input: String) async throws -> String {
///         return "Hello, \(input)!"
///     }
/// }
/// ```
public protocol ActivityDefinition: Sendable {
    /// The input type for the activity.
    associatedtype Input: Sendable

    /// The output type for the activity.
    associatedtype Output: Sendable

    /// The activity name used for registration and execution.
    ///
    /// This identifier is used by Temporal to route activity execution requests to the appropriate implementation.
    /// Defaults to the string representation of the conforming type.
    static var name: String { get }

    /// A Boolean value that indicates whether this activity is a dynamic activity that handles unregistered activity types.
    ///
    /// Dynamic activities act as catch-all handlers for activity types that are not explicitly registered
    /// with the worker. When the worker receives a task for an unregistered activity type and a dynamic
    /// activity is registered, the task is routed to the dynamic activity instead of failing.
    ///
    /// Dynamic activities must use `[TemporalRawValue]` as their ``Input`` type to receive
    /// the raw arguments. The activity type name is available via
    /// ``ActivityExecutionContext/info``'s ``ActivityExecutionContext/Info-swift.struct/activityType``.
    ///
    /// A worker can have at most one dynamic activity registered. Dynamic activities cannot have
    /// a custom name -- the name is ignored when ``isDynamic`` returns `true`.
    ///
    /// Default is `false`.
    static var isDynamic: Bool { get }

    /// Executes the activity with the provided input.
    ///
    /// This method contains the core logic of the activity and will be invoked by the Temporal worker
    /// when the activity is scheduled for execution.
    ///
    /// - Parameter input: The input data for the activity execution.
    /// - Returns: The result of the activity execution.
    /// - Throws: Any error that occurs during activity execution.
    func run(input: Input) async throws -> Output
}

extension ActivityDefinition {
    public static var name: String {
        String(describing: self)
    }

    public static var isDynamic: Bool {
        false
    }
}
