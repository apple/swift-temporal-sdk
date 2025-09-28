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

/// A wrapper that makes workflow state `Sendable` by ensuring it is modified on the workflow's executor.
///
/// `_WorkflowState` ensures that all modifications to workflow state happen safely within
/// the workflow's execution context. It enforces that state can only be accessed and
/// modified on the workflow's dedicated executor, preventing race conditions and ensuring
/// deterministic execution during workflow replay.
public struct _WorkflowState<Value>: @unchecked Sendable {
    /// The wrapped value that is protected by the workflow's executor.
    public var value: Value {
        get {
            Workflow.ensureWorkflowStateModificationIsSafe()
            return self._value
        }
        set {
            Workflow.ensureWorkflowStateModificationIsSafe()
            self._value = newValue
        }
    }

    private var _value: Value

    /// Creates a new workflow state wrapper with the specified initial value.
    ///
    /// - Parameter initialValue: The initial value to be wrapped and managed by the workflow state.
    public init(initialValue: Value) {
        self._value = initialValue
    }
}
