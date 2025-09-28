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

extension Coresdk_WorkflowCommands_ContinueAsNewWorkflowExecution {
    init(continueAsNewError: ContinueAsNewError) {
        self = .with {
            $0.workflowType = continueAsNewError.workflowName
            $0.taskQueue = continueAsNewError.taskQueue
            $0.arguments = continueAsNewError.inputs.map { .init(temporalPayload: $0) }
            $0.memo = continueAsNewError.memo.flatMap { $0.mapValues { .init(temporalPayload: $0.payload) } } ?? [:]
            $0.retryPolicy = .init(retryPolicy: continueAsNewError.retryPolicy ?? .init())
        }

        if let runTimeout = continueAsNewError.runTimeout {
            self.workflowRunTimeout = .init(duration: runTimeout)
        }

        if let taskTimeout = continueAsNewError.taskTimeout {
            self.workflowTaskTimeout = .init(duration: taskTimeout)
        }

        if let searchAttributes = continueAsNewError.searchAttributes, !searchAttributes.isEmpty {
            self.searchAttributes = Temporal_Api_Common_V1_SearchAttributes(searchAttributes).indexedFields
        }

        if !continueAsNewError.headers.isEmpty {
            self.headers = continueAsNewError.headers.mapValues { .init(temporalPayload: $0) }
        }
    }
}
