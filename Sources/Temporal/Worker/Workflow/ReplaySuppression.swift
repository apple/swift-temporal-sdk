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

/// Whether workflow code on the current task is currently replaying.
///
/// Instruments handed to workflow code consult this before emitting a signal, so that a statement in
/// workflow code produces one signal rather than one per replayed workflow task.
///
/// An instrument might have been carried off the workflow executor — a metric handler stored in a
/// `let` and used from a detached task, for instance — so the replay flag is only read while the
/// caller is still running on the workflow executor. Everywhere else this reports `false` and the
/// signal is emitted normally.
package func isWorkflowReplaying() -> Bool {
    guard let current = InternalWorkflowContext.current, current.stateMachine.isOnExecutor() else {
        return false
    }
    return current.isReplaying
}
