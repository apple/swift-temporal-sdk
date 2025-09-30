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

/// The retry state of a workflow or activity.
// TODO: Revisit this before major regarding extensible enums
public enum RetryState: Hashable, Sendable {
    /// Indicates that workflow/acitivity is in a unspecified progress.
    case unspecified
    /// Indicates that workflow/acitivity is in progress.
    case inProgress
    /// Indicates that workflow/acitivity is in a non retryable failure state.
    case nonRetryableFailure
    /// Indicates that workflow/acitivity timed out.
    case timeout
    /// Indicates that workflow/acitivity that the retry policy hasn't been set.
    case retryPolicyNotSet
    /// Indicates that workflow/acitivity has reached the maximum retry attempts.
    case maximumAttemptsReached
    /// Indicates that workflow/acitivity is in an internal server error state.
    case internalServerError
    /// Indicates that workflow/acitivity was requested to cancel..
    case cancelRequested
}
