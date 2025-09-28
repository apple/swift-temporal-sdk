//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Temporal SDK open source project
//
// Copyright (c) 2025 Apple Inc. and the Swift Temporal SDK project authors
// Licensed under MIT License
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Swift Cassandra Client project authors
//
// SPDX-License-Identifier: MIT
//
//===----------------------------------------------------------------------===//

/// How already-in-use workflow IDs are handled on start.
///
/// See also:  [https://docs.temporal.io/workflows#workflow-id-reuse-policy](https://docs.temporal.io/workflows#workflow-id-reuse-policy)
// TODO: Revisit this before major regarding extensible enums
public enum WorkflowIDReusePolicy: Hashable, Sendable {
    case unspecified

    /// Allow starting a workflow execution using the same workflow ID.
    case allowDuplicate
    /// Allow starting a workflow execution using the same workflow ID, only when the last execution's final state is one
    /// of terminated, canceled, timed out, or failed
    case allowDuplicateFailedOnly
    /// Do not permit re-use of the workflow ID for this workflow. Future start workflow requests could potentially change
    /// the policy, allowing re-use of the workflow ID.
    case rejectDuplicate
    /// This option is ``WorkflowIDConflictPolicy/terminateExisting`` but is here for backwards compatibility. If
    /// specified, it acts like ``allowDuplicate``, but also the ``WorkflowIDConflictPolicy`` on the request is treated as
    /// ``WorkflowIDConflictPolicy/terminateExisting``. If no running workflow, then the behavior is the same as
    /// ``allowDuplicate``.
    ///
    /// - Note: Deprecated - Use ``WorkflowIDConflictPolicy/terminateExisting`` instead.
    case terminateIfRunning

    var description: String {
        switch self {
        case .allowDuplicate:
            return "allowDuplicate"
        case .allowDuplicateFailedOnly:
            return "allowDuplicateFailedOnly"
        case .rejectDuplicate:
            return "rejectDuplicate"
        case .terminateIfRunning:
            return "terminateIfRunning"
        case .unspecified:
            return "unspecified"
        }
    }
}
