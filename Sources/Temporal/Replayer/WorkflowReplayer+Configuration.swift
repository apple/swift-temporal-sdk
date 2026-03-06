//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Temporal SDK open source project
//
// Copyright (c) 2026 Apple Inc. and the Swift Temporal SDK project authors
// Licensed under MIT License
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Swift Temporal SDK project authors
//
// SPDX-License-Identifier: MIT
//
//===----------------------------------------------------------------------===//

public import Logging

extension WorkflowReplayer {
    /// Configuration options for a ``WorkflowReplayer``.
    public struct Configuration: Sendable {
        /// The workflow types registered for replay.
        public var workflows: [any WorkflowDefinition.Type]

        /// The namespace used for replay context.
        public var namespace: String

        /// The task queue used for replay context.
        public var taskQueue: String

        /// The data converter used for serializing and deserializing payloads.
        public var dataConverter: DataConverter

        /// The interceptors to apply during replay.
        public var interceptors: [any WorkerInterceptor]

        /// A logger for diagnostic output during replay.
        public var logger: Logger

        /// Creates a new replayer configuration.
        ///
        /// - Parameters:
        ///   - workflows: The workflow types to register for replay. At least one workflow
        ///     must be registered before creating a replayer.
        ///   - namespace: The namespace for replay context. Defaults to `"ReplayNamespace"`.
        ///   - taskQueue: The task queue for replay context. Defaults to `"ReplayTaskQueue"`.
        ///   - dataConverter: The data converter for payload serialization. Defaults to
        ///     ``DataConverter/default``.
        ///   - interceptors: The interceptors to apply during replay. Defaults to an empty
        ///     array (no interceptors).
        ///   - logger: The logger for diagnostic output. Defaults to a logger with label
        ///     `"WorkflowReplayer"`.
        public init(
            workflows: [any WorkflowDefinition.Type] = [],
            namespace: String = "ReplayNamespace",
            taskQueue: String = "ReplayTaskQueue",
            dataConverter: DataConverter = .default,
            interceptors: [any WorkerInterceptor] = [],
            logger: Logger = Logger(label: "WorkflowReplayer")
        ) {
            self.workflows = workflows
            self.namespace = namespace
            self.taskQueue = taskQueue
            self.dataConverter = dataConverter
            self.interceptors = interceptors
            self.logger = logger
        }
    }
}
