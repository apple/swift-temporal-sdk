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

/// Identifies the version(s) of a worker that processed a task.
/// - Note: Deprecated - This is replaced with `Deployment` and `VersioningBehavior`.
public struct WorkerVersionStamp: Hashable, Sendable {
    /// An opaque whole-worker identifier.
    ///
    /// Replaces the deprecated `binary_checksum` field when this message is included in requests which previously used that.
    public var buildID: String

    /// If set, the worker is opting in to worker versioning. Otherwise, this is used only as a
    /// marker for workflow reset points and the BuildIDs search
    public var useVersioning: Bool
}
