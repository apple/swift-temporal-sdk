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

/// Error thrown by a workflow out of the ``WorkflowDefinition/run(input:)``
/// method to issue a continue-as-new.
public struct ContinueAsNewError: TemporalError {
    /// The error's message.
    public var message = "Continue as new"

    /// The cause of the current error.
    public var cause: (any Error)? = nil

    /// The stack trace of the current error.
    public var stackTrace: String

    /// The workflow's name.
    var workflowName: String

    /// The workflow's inputs.
    var inputs: [TemporalPayload]

    /// The headers for continue as new.
    var headers: [String: TemporalPayload]

    /// The task queue to continue as new.
    var taskQueue: String

    /// The task timeout for continue as new.
    var taskTimeout: Duration?

    /// The run timeout for continue as new.
    var runTimeout: Duration?

    /// The retry policy for continue as new.
    var retryPolicy: RetryPolicy?

    /// The memo for continue as new.
    var memo: [String: TemporalRawValue]?

    /// The search attributes for continue as new.
    var searchAttributes: SearchAttributeCollection?

    init(
        workflowContext: WorkflowContext,
        headers: [String: TemporalPayload],
        inputs: [TemporalPayload],
        options: ContinueAsNewOptions,
        payloadConverter: any PayloadConverter
    ) throws {
        self.stackTrace = ""
        self.workflowName = workflowContext.info.workflowName
        self.inputs = inputs
        self.headers = headers
        self.taskQueue = options.taskQueue ?? workflowContext.info.taskQueue
        self.taskTimeout = options.taskTimeout ?? workflowContext.info.taskTimeout
        self.runTimeout = options.runTimeout ?? workflowContext.info.runTimeout
        self.retryPolicy = options.retryPolicy ?? workflowContext.info.retryPolicy
        if let memo = options.memo {
            var convertedMemo = [String: TemporalRawValue]()
            for (key, value) in memo {
                do {
                    let payload = try payloadConverter.convertValueHandlingVoid(value)
                    convertedMemo[key] = .init(payload)
                } catch {
                    throw ArgumentError(message: "Failed to convert memo value for key \(key). Underlying error \(type(of: error))")
                }
            }
            self.memo = convertedMemo
        } else {
            self.memo = workflowContext.memo()
        }

        let inheritedSearchAttributes = workflowContext.searchAttributes
        let searchAttributes = options.searchAttributes ?? .init()
        let mergedAttributes = inheritedSearchAttributes.merging(searchAttributes) { $1 }
        if !mergedAttributes.isEmpty {
            self.searchAttributes = mergedAttributes
        }
    }
}
