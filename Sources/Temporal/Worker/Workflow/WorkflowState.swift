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

/// A wrapper that makes workflow state `Sendable` by ensuring it is modified on the workflow's executor.
///
/// `_WorkflowState` ensures that all modifications to workflow state happen safely within
/// the workflow's execution context. It enforces that state can only be accessed and
/// modified on the workflow's dedicated executor, preventing race conditions and ensuring
/// deterministic execution during workflow replay.
public struct _WorkflowState<Value: Sendable>: @unchecked Sendable {
    /// The reference-backed box holding the value.
    private let box: ArcBox<Value>

    /// The wrapped value.
    ///
    /// The getter is non-mutating and always callable, reading through the shared box.
    /// The setter is implicitly mutating (struct default), so it can only be called
    /// from mutating methods, providing compile-time mutation control.
    public var value: Value {
        get {
            Self.ensureOnWorkflowExecutor()
            return box.value
        }
        set {
            Self.ensureOnWorkflowExecutor()
            box.value = newValue
        }
    }

    private static func ensureOnWorkflowExecutor() {
        // Allow access if the workflow instance itself is modifying the state
        if WorkflowInstance.isOnWorkflowInstance {
            return
        }

        guard let executor = InternalWorkflowContext.currentExecutor else {
            fatalError("Workflow state can only be accessed from within a workflow execution")
        }
        withUnsafeCurrentTask { currentTask in
            guard let currentTask else {
                fatalError("Current task not found during workflow state access")
            }
            guard currentTask.unownedTaskExecutor == executor.asUnownedTaskExecutor() else {
                fatalError("Workflow state can only be accessed from the workflow executor")
            }
        }
    }

    /// Creates a new workflow state wrapper with the specified initial value.
    ///
    /// - Parameter initialValue: The initial value to be wrapped and managed by the workflow state.
    public init(initialValue: Value) {
        self.box = ArcBox(initialValue)
    }
}
