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

import Logging
import Synchronization

/// A simple in‐memory `LogHandler` for testing.
final class InMemoryLogHandler: LogHandler {
    let entries = Mutex<[LogEvent]>([])

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

    func log(event: LogEvent) {
        var mergedMetadata = self._metadata.withLock { $0 }

        if let provider = self.metadataProvider {
            let contextual = provider.get()
            if !contextual.isEmpty {
                mergedMetadata.merge(contextual) { _, new in new }
            }
        }

        if let explicitMetadata = event.metadata {
            mergedMetadata.merge(explicitMetadata) { _, new in new }
        }

        var event = event
        event.metadata = mergedMetadata

        self.entries.withLock {
            $0.append(event)
        }
    }

    subscript(metadataKey key: String) -> Logger.Metadata.Value? {
        get { self.metadata[key] }
        set { self.metadata[key] = newValue }
    }
}
