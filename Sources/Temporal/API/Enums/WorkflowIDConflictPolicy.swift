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

/// How already-running workflows of the same ID are handled on start.
///
/// See also: [https://docs.temporal.io/workflows#workflow-id-conflict-policy](https://docs.temporal.io/workflows#workflow-id-conflict-policy)
// TODO: Revisit this before major regarding extensible enums
public enum WorkflowIDConflictPolicy: Hashable, Sendable {
    /// Unset.
    case unspecified
    /// Don't start a new workflow, instead fail with already-started error.
    case fail
    /// Don't start a new workflow, instead return a workflow handle for the running workflow.
    case useExisting
    /// Terminate the running workflow before starting a new one.
    case terminateExisting
}
