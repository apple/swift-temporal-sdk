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

/// Defines how parent workflows handle child workflow cancellation requests and completion confirmation.
///
/// Child workflow cancellation types control the parent workflow's behavior when cancelling a child
/// workflow execution, determining whether to wait for acknowledgment, proceed immediately, or
/// abandon the child workflow without sending cancellation requests.
///
/// ## Cancellation flow
///
/// Child workflow cancellation involves several coordination steps:
/// 1. Parent workflow initiates cancellation based on this type
/// 2. Cancellation request sent to child workflow (if requested)
/// 3. Child workflow receives and processes cancellation signal
/// 4. Child workflow responds with cancellation acknowledgment or completion
/// 5. Parent workflow receives confirmation (if waiting)
///
/// ## Behavioral trade-offs
///
/// Different cancellation types offer varying trade-offs between:
/// - **Response Time**: How quickly the parent workflow can continue execution
/// - **Resource Cleanup**: Ensuring child workflows properly clean up resources
/// - **Reliability**: Guaranteeing cancellation requests are received and processed
///
/// ## Usage considerations
///
/// - **Response Priority**: Use ``tryCancel`` when parent workflow responsiveness is critical
/// - **Cleanup Assurance**: Use ``waitCancellationCompleted`` when child cleanup is essential
/// - **Request Confirmation**: Use ``waitCancellationRequested`` for reliable cancellation delivery
/// - **Performance Optimization**: Use ``abandon`` when child results are no longer needed
///
/// The default cancellation type is ``waitCancellationCompleted``, which balances reliability
/// with proper resource cleanup for most use cases.
// TODO: Revisit this before major regarding extensible enums
public enum ChildWorkflowCancellationType: Hashable, Sendable {
    /// Does not request child workflow cancellation and immediately reports cancellation to the parent workflow.
    ///
    /// This option skips sending any cancellation signal to the child workflow and immediately
    /// treats it as cancelled from the parent workflow perspective. The child workflow continues
    /// running until natural completion or timeout, but its results are ignored.
    case abandon

    /// Initiates a cancellation request and immediately reports cancellation to the parent workflow.
    ///
    /// This option sends a cancellation signal to the child workflow and continues parent workflow
    /// execution without waiting for the child to acknowledge or complete the cancellation. The parent
    /// workflow treats the child as cancelled immediately.
    case tryCancel

    /// Waits for child workflow cancellation completion before continuing parent workflow execution.
    ///
    /// This option sends a cancellation signal to the child workflow and blocks parent workflow
    /// execution until the child workflow acknowledges the cancellation and completes its cleanup.
    /// This ensures orderly resource cleanup but may block indefinitely if the child doesn't respond.
    case waitCancellationCompleted

    /// Requests child workflow cancellation and waits for confirmation that the request was received.
    ///
    /// This option sends a cancellation signal to the child workflow and waits for acknowledgment
    /// that the cancellation request was received and accepted by the child workflow system.
    /// It provides a middle ground between immediate continuation and full completion waiting.
    case waitCancellationRequested

    /// Returns a string description of the cancellation type for debugging and logging purposes.
    ///
    /// - Returns: A string representation of the cancellation type.
    var description: String {
        switch self {
        case .abandon: "abandon"
        case .tryCancel: "tryCancel"
        case .waitCancellationCompleted: "waitCancellationCompleted"
        case .waitCancellationRequested: "waitCancellationRequested"
        }
    }
}
