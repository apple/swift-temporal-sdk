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

/// Specifies the versioning intent for workflow commands determining worker build ID compatibility requirements.
///
/// Versioning intent controls how Temporal routes child workflows and activities to workers with specific build
/// IDs, enabling safe deployment and rollback strategies in production environments with multiple code versions.
// TODO: Revisit this before major regarding extensible enums
public enum VersioningIntent: Hashable, Sendable {
    /// Allows the system to choose the most appropriate versioning behavior based on command type and context.
    case unspecified

    /// Routes the command to a worker with a build ID compatible with the current worker's version.
    ///
    /// This intent attempts to maintain version compatibility by routing commands to workers
    /// that share the same build ID or belong to the same compatibility set. This ensures
    /// that workflows and activities execute on code versions that can safely interoperate.
    case compatible

    /// Routes the command to a worker using the target task queue's current overall-default build ID.
    ///
    /// This intent directs commands to workers running the latest default version on the target
    /// task queue, regardless of the current worker's build ID. This enables workflows to
    /// leverage the most recent code deployments and feature updates.
    case currentDefault

    /// Returns a string description of the versioning intent for debugging and logging purposes.
    ///
    /// This property provides human-readable names for each versioning intent, useful for
    /// logging, debugging, and diagnostic output when tracing workflow routing decisions.
    ///
    /// - Returns: A string representation of the versioning intent.
    package var description: String {
        switch self {
        case .unspecified: "unspecified"
        case .compatible: "compatible"
        case .currentDefault: "currentDefault"
        }
    }
}
