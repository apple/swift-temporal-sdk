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

public struct TaskQueue: Hashable, Sendable {
    public var name: String
    public var kind: Kind

    public init(name: String, kind: Kind) {
        self.name = name
        self.kind = kind
    }
}

extension TaskQueue {
    public enum Kind: Hashable, Sendable {
        case unspecified

        /// Tasks from a normal workflow task queue always include complete workflow history
        ///
        /// The task queue specified by the user is always a normal task queue. There can be as many
        /// workers as desired for a single normal task queue. All those workers may pick up tasks from
        /// that queue.
        case normal

        /// A sticky queue only includes new history since the last workflow task, and they are
        /// per-worker.
        ///
        /// Sticky queues are created dynamically by each worker during their start up. They only exist
        /// for the lifetime of the worker process. Tasks in a sticky task queue are only available to
        /// the worker that created the sticky queue.
        ///
        /// Sticky queues are only for workflow tasks. There are no sticky task queues for activities.
        case sticky
    }
}
