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

/// A unique identifier for an activity execution.
///
/// The activity task token serves as a unique identifier for an activity execution instance
/// within the Temporal system. It's used to track the activity's lifecycle and ensure
/// proper correlation between activity heartbeats, completions, and cancellations.
///
/// ## Usage
///
/// Activity task tokens are typically managed internally by the Temporal SDK and are not
/// directly manipulated by user code. They are automatically provided in the
/// ``ActivityExecutionContext/Info/taskToken`` during activity execution.
///
/// ```swift
/// // Access the task token from within an activity
/// let context = ActivityExecutionContext.current!
/// let taskToken = context.info.taskToken
/// ```
public struct ActivityTaskToken: Hashable, Sendable {
    /// The raw bytes that comprise the unique token.
    ///
    /// This binary data uniquely identifies the activity execution instance within the Temporal system.
    public var bytes: [UInt8]

    /// Creates a new activity task token with the specified bytes.
    ///
    /// - Parameter bytes: The raw bytes that comprise the unique token.
    public init(bytes: [UInt8]) {
        self.bytes = bytes
    }
}
