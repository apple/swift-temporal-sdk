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

/// An inbound interceptor that binds the workflow's logger as the task local logger.
///
/// This is always installed as the outermost inbound interceptor of a workflow instance so that
/// user interceptors and workflow code observe the workflow's logger through `Logger.current`.
/// The binding is made inside the task running each entry point, so tasks spawned from there
/// inherit it and it can't leak into other workflows sharing the worker.
struct TaskLocalLoggerWorkflowInboundInterceptor: WorkflowInboundInterceptor {
    /// The logger of the workflow instance.
    let logger: Logger

    func executeWorkflow<Workflow>(
        input: ExecuteWorkflowInput<Workflow>,
        next: (ExecuteWorkflowInput<Workflow>) async throws -> Workflow.Output
    ) async throws -> Workflow.Output {
        try await withLogger(self.logger) { _ in
            try await next(input)
        }
    }

    func handleSignal<Signal>(
        input: HandleSignalInput<Signal>,
        next: (HandleSignalInput<Signal>) async throws -> Void
    ) async throws {
        try await withLogger(self.logger) { _ in
            try await next(input)
        }
    }

    func handleQuery<Query>(
        input: HandleQueryInput<Query>,
        next: (HandleQueryInput<Query>) throws -> Query.Output
    ) throws -> Query.Output {
        try withLogger(self.logger) { _ in
            try next(input)
        }
    }

    func handleUpdate<Update>(
        input: HandleUpdateInput<Update>,
        next: (HandleUpdateInput<Update>) async throws -> Update.Output
    ) async throws -> Update.Output {
        try await withLogger(self.logger) { _ in
            try await next(input)
        }
    }

    func validateUpdate<Update>(
        input: HandleUpdateInput<Update>,
        next: (HandleUpdateInput<Update>) throws -> Void
    ) throws {
        try withLogger(self.logger) { _ in
            try next(input)
        }
    }
}
