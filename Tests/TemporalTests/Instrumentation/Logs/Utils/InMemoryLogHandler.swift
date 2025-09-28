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

import Logging
import Synchronization

/// A simple in‐memory `LogHandler` for testing.
final class InMemoryLogHandler: LogHandler {
    struct LogEntry: Sendable {
        let level: Logger.Level
        let message: Logger.Message
        let metadata: Logger.Metadata?
        let source: String
        let file: String
        let function: String
        let line: UInt
    }

    let entries = Mutex<[LogEntry]>([])

    private let _logLevel: Mutex<Logger.Level> = .init(.trace)  // collect all logs
    var logLevel: Logger.Level {
        get {
            self._logLevel.withLock { $0 }
        }

        set {
            self._logLevel.withLock { $0 = newValue }
        }
    }

    private let _metadata: Mutex<Logger.Metadata> = .init([:])
    var metadata: Logger.Metadata {
        get {
            self._metadata.withLock { $0 }
        }

        set {
            self._metadata.withLock { $0 = newValue }
        }
    }

    let metadataProvider: Logger.MetadataProvider?

    init(metadataProvider: Logger.MetadataProvider? = nil) {
        self.metadataProvider = metadataProvider
    }

    func log(
        level: Logger.Level,
        message: Logger.Message,
        metadata explicitMetadata: Logger.Metadata?,
        source: String,
        file: String,
        function: String,
        line: UInt
    ) {
        var mergedMetadata = self._metadata.withLock { $0 }

        if let provider = self.metadataProvider {
            let contextual = provider.get()
            if !contextual.isEmpty {
                mergedMetadata.merge(contextual) { _, new in new }
            }
        }

        if let explicitMetadata {
            mergedMetadata.merge(explicitMetadata) { _, new in new }
        }

        let entry = LogEntry(
            level: level,
            message: message,
            metadata: mergedMetadata,
            source: source,
            file: file,
            function: function,
            line: line
        )

        self.entries.withLock {
            $0.append(entry)
        }
    }

    subscript(metadataKey key: String) -> Logger.Metadata.Value? {
        get { self.metadata[key] }
        set { self.metadata[key] = newValue }
    }
}
