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

/// The error types that fail a workflow execution instead of its workflow task.
///
/// An error matches if it can be cast to one of the types, the same way `catch let error as T` matches.
package struct WorkflowFailureErrorTypes: Sendable {
    private let types: [any Error.Type]

    /// Creates the error types from a list of error types.
    ///
    /// - Parameter types: The error types that fail a workflow execution.
    package init(_ types: [any Error.Type]) {
        self.types = types
    }

    /// Returns whether the error can be cast to one of the error types.
    ///
    /// - Parameter error: The error thrown by the workflow.
    package func contains(_ error: any Error) -> Bool {
        self.types.contains { Self.error(error, isOf: $0) }
    }

    /// Whether nondeterminism fails the workflow execution.
    ///
    /// Nondeterminism is detected by Core and never thrown, so this checks a stand-in
    /// ``WorkflowNondeterminismError``.
    package var matchesNondeterminism: Bool {
        self.contains(WorkflowNondeterminismError(message: "Nondeterminism"))
    }

    private static func error<ErrorType: Error>(_ error: any Error, isOf _: ErrorType.Type) -> Bool {
        error is ErrorType
    }
}

extension WorkflowFailureErrorTypes {
    /// The names of the workflows whose own failure error types match nondeterminism.
    ///
    /// These are the values for Core's `nondeterminism_as_workflow_fail_for_types` worker option.
    ///
    /// - Parameter workflows: The workflows registered with the worker.
    package static func workflowTypesFailingOnNondeterminism(in workflows: [any WorkflowDefinition.Type]) -> [String] {
        workflows
            .filter { WorkflowFailureErrorTypes($0.failureErrorTypes).matchesNondeterminism }
            .map { $0.name }
    }
}
