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

public enum SignalExternalWorkflowExecutionFailedCause: Hashable, Sendable {
    case unspecified
    case externalWorkflowExecutionNotFound
    case namespaceNotFound

    /// Signal count limit is per workflow and controlled by server dynamic config "history.maximumSignalsPerExecution"
    case signalCountLimitExceeded
}
