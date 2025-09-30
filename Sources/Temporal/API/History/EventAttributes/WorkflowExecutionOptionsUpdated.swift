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
    /// Event attributes for when workflow execution options have been updated.
    public struct WorkflowExecutionOptionsUpdated: Hashable, Sendable {
        /// Versioning override upserted in this event.
        ///
        /// Ignored if nil or if unset_versioning_override is true.
        public var versioningOverride: VersioningOverride

        /// Versioning override removed in this event.
        public var unsetVersioningOverride: Bool

        /// Request ID attachedto the running workflow execution so that subsequent requests with same
        /// request ID will be deduped.
        public var attachedRequestID: String?

        /// Completion callbacks attached to the running workflow execution.
        public var attachedCompletionCallbacks: [Callback]

        public init(
            versioningOverride: VersioningOverride,
            unsetVersioningOverride: Bool,
            attachedRequestID: String?,
            attachedCompletionCallbacks: [Callback]
        ) {
            self.versioningOverride = versioningOverride
            self.unsetVersioningOverride = unsetVersioningOverride
            self.attachedRequestID = attachedRequestID
            self.attachedCompletionCallbacks = attachedCompletionCallbacks
        }
    }
}
