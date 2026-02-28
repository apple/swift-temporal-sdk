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

/// Result of an activity execution.
enum ActivityExecutionResult: Hashable, Sendable {
    /// Activity finished successfully with a result.
    case completed(result: Api.Common.V1.Payload)
    /// Activity failed with a failure.
    case failed(failure: Api.Failure.V1.Failure)
    /// Activity was cancelled with a cancellation failure.
    case cancelled(failure: Api.Failure.V1.Failure)
    /// Activity will be completed asynchronously.
    case willCompleteAsync
}
