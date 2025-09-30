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

extension HistoryEvent.Attributes {
    public struct WorkflowExecutionTimedOut: Hashable, Sendable {
        public var retryState: RetryState

        /// If another run is started by cron or retry, this contains the new run id.
        public var newExecutionRunID: String?

        public init(retryState: RetryState, newExecutionRunID: String? = nil) {
            self.retryState = retryState
            self.newExecutionRunID = newExecutionRunID
        }
    }
}
