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

extension ActivityOptions {
    /// Defines workflow behavior when cancelling activity execution and handling cancellation confirmation.
    ///
    /// The cancellation type controls how workflows respond to activity cancellation requests,
    /// determining whether to wait for acknowledgment, proceed immediately, or abandon the activity
    /// without cancellation. This affects workflow execution flow and resource cleanup behavior.
    ///
    /// ## Cancellation flow
    ///
    /// Activity cancellation involves several steps:
    /// 1. Workflow initiates cancellation (based on this type)
    /// 2. Cancellation signal sent to activity worker (if requested)
    /// 3. Activity receives signal via heartbeat mechanism
    /// 4. Activity responds to cancellation (cleanup, completion, or ignore)
    /// 5. Workflow receives cancellation confirmation (if waiting)
    ///
    /// ## Heartbeat dependency
    ///
    /// Activities must send regular heartbeats to receive cancellation signals. Without heartbeats,
    /// cancellation requests cannot reach the activity.
    ///
    /// ## Usage considerations
    ///
    /// - **Response Time**: ``tryCancel`` provides immediate workflow continuation
    /// - **Resource Cleanup**: ``waitCancellationCompleted`` ensures proper activity cleanup
    /// - **Performance**: ``abandon`` avoids cancellation overhead for disposable activities
    ///
    /// ## Default behavior
    ///
    /// The default cancellation type is ``tryCancel``, which balances responsiveness with
    /// reasonable cancellation attempts for most use cases.
    public enum CancellationType: Hashable, Sendable {
        /// Initiates cancellation request and immediately reports cancellation to the workflow.
        ///
        /// This option sends a cancellation signal to the activity and continues workflow execution
        /// without waiting for the activity to acknowledge or complete the cancellation. The workflow
        /// treats the activity as cancelled immediately.
        case tryCancel

        /// Waits for activity cancellation completion before continuing workflow execution.
        ///
        /// This option sends a cancellation signal to the activity and blocks workflow execution
        /// until the activity acknowledges the cancellation and completes its cleanup. This ensures
        /// orderly resource cleanup but may block indefinitely if the activity doesn't respond.
        case waitCancellationCompleted

        /// Does not request activity cancellation and immediately reports cancellation to the workflow.
        ///
        /// This option skips sending any cancellation signal to the activity and immediately
        /// treats it as cancelled from the workflow perspective. The activity continues running
        /// until completion or timeout, but its results are ignored.
        case abandon

        /// Extensibility marker preventing exhaustive matching over this enumeration.
        ///
        /// This case enables future expansion of cancellation types without breaking existing code.
        /// It should never be used directly and will cause a fatal error if encountered.
        ///
        /// - Warning: Do not use this case directly. It exists only for future extensibility.
        case DO_NOT_EXHAUSTIVELY_MATCH_OVER_THIS_ENUM

        /// Returns a string description of the cancellation type for debugging and logging purposes.
        ///
        /// - Returns: A string representation of the cancellation type.
        package var description: String {
            switch self {
            case .tryCancel:
                "tryCancel"
            case .waitCancellationCompleted:
                "waitCancellationCompleted"
            case .abandon:
                "abandon"
            case .DO_NOT_EXHAUSTIVELY_MATCH_OVER_THIS_ENUM:
                fatalError("Unhandled case")
            }
        }
    }
}
