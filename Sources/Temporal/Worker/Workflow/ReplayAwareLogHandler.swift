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

package import Logging

/// A log handler that drops records while the workflow is replaying.
///
/// Workflow code runs again from the beginning on every replay, so without this every log statement in
/// a workflow is emitted once per replayed workflow task. The Go and .NET SDKs suppress workflow logs
/// the same way.
package struct ReplayAwareLogHandler: LogHandler {
    private var underlying: any LogHandler

    package var metadata: Logger.Metadata {
        get {
            self.underlying.metadata
        }
        set {
            self.underlying.metadata = newValue
        }
    }

    package var metadataProvider: Logger.MetadataProvider? {
        get {
            self.underlying.metadataProvider
        }
        set {
            self.underlying.metadataProvider = newValue
        }
    }

    package var logLevel: Logger.Level {
        get {
            self.underlying.logLevel
        }
        set {
            self.underlying.logLevel = newValue
        }
    }

    package init(underlying: any LogHandler) {
        self.underlying = underlying
    }

    package subscript(metadataKey metadataKey: String) -> Logger.Metadata.Value? {
        get {
            self.underlying[metadataKey: metadataKey]
        }
        set {
            self.underlying[metadataKey: metadataKey] = newValue
        }
    }

    package func log(event: LogEvent) {
        // The logger might have moved off the Workflow Executor, so only contact `isReplaying` if we are running on the Workflow Executor
        if let current = InternalWorkflowContext.current, current.stateMachine.isOnExecutor() {
            guard !current.isReplaying else {
                return
            }
        }

        self.underlying.log(event: event)
    }
}
