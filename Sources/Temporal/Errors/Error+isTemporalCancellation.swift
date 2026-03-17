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

extension Error {
    /// Whether this error represents a Temporal cancellation from a workflow, activity, or child workflow.
    ///
    /// This is useful when catching errors in workflow code to determine whether they represent
    /// a cancellation. When an activity or child workflow is cancelled, the cancellation may be
    /// thrown directly as ``CanceledError`` or wrapped inside an ``ActivityError`` or
    /// ``ChildWorkflowError``. This property handles all cases, making cancellation detection
    /// straightforward in catch clauses.
    public var isTemporalCancellation: Bool {
        switch self {
        case is CancellationError:
            true
        case is CanceledError:
            true
        case let error as ActivityError:
            error.cause is CanceledError
        case let error as ChildWorkflowError:
            error.cause is CanceledError
        default:
            false
        }
    }
}
