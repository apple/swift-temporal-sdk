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

/// A box ensuring that a value is always accessed from the correct executor.
///
/// This allows us to send non-Sendable workflows across child tasks as long as they are on the right executor.
struct WorkflowTaskExecutorIsolatedBox<Wrapped>: @unchecked Sendable {
    /// The executor.
    let executor: WorkflowTaskExecutor

    /// The value bound to the executor.
    var wrapped: Wrapped {
        get {
            self.ensureOnExecutor()
            return self._wrapped
        }
    }

    private var _wrapped: Wrapped

    init(executor: WorkflowTaskExecutor, wrapped: Wrapped) {
        self.executor = executor
        self._wrapped = wrapped
    }

    private func ensureOnExecutor() {
        // This is using custom logic instead of preconditionIsolated to ensure
        // the error messages are printed on crash.
        withUnsafeCurrentTask { currentTask in
            guard let currentTask else {
                fatalError("Current task not found")
            }
            guard currentTask.unownedTaskExecutor == executor.asUnownedTaskExecutor() else {
                fatalError("Current task executor mismatch")
            }
        }
    }
}
