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
}
