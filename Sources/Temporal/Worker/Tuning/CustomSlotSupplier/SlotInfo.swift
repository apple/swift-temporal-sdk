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

/// Information about a specific task occupying a reserved slot.
@nonexhaustive
public enum SlotInfo: Sendable {
    /// A workflow task. ``isSticky`` is `true` when delivered on the sticky queue.
    case workflow(workflowType: String, isSticky: Bool)
    /// A regular activity task.
    case activity(activityType: String)
    /// A local activity task.
    case localActivity(activityType: String)
    /// A Nexus operation task.
    case nexus(service: String, operation: String)
}
