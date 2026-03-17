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

/// Information about the currently executing workflow update.
///
/// This type provides metadata about the update that is currently being handled
/// within an update handler. It is only available during the execution of an
/// update handler and will be `nil` outside of that context.
public struct WorkflowUpdateInfo: Sendable {
    /// The unique identifier for this update request.
    public var id: String

    /// The name identifying the type of update being executed.
    public var name: String

    /// Creates a new workflow update info instance.
    ///
    /// - Parameters:
    ///   - id: The unique identifier for this update request.
    ///   - name: The name identifying the type of update.
    public init(id: String, name: String) {
        self.id = id
        self.name = name
    }
}
