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

/// Records why a WorkflowExecutionUpdateAdmittedEvent was written to history.
///
/// Note that not all admitted Updates result in this event.
public enum UpdateAdmittedEventOrigin: Hashable, Sendable {
    case unspecified

    /// The UpdateAdmitted event was created when reapplying events during reset
    /// or replication. I.e. an accepted Update on one branch of Workflow history
    /// was converted into an admitted Update on a different branch.
    case reapply
}
