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

import SwiftProtobuf

extension Coresdk.WorkflowCommands.ContinueAsNewWorkflowExecution {
    init(continueAsNewError: ContinueAsNewError) {
        self = .with {
            $0.workflowType = continueAsNewError.workflowName
            $0.taskQueue = continueAsNewError.taskQueue
            $0.arguments = continueAsNewError.inputs
            $0.memo = continueAsNewError.memo.flatMap { $0.mapValues { $0.payload } } ?? [:]
            $0.retryPolicy = .init(retryPolicy: continueAsNewError.retryPolicy ?? .init())
        }

        if let runTimeout = continueAsNewError.runTimeout {
            self.workflowRunTimeout = .init(duration: runTimeout)
        }

        if let taskTimeout = continueAsNewError.taskTimeout {
            self.workflowTaskTimeout = .init(duration: taskTimeout)
        }

        if let searchAttributes = continueAsNewError.searchAttributes, !searchAttributes.isEmpty {
            self.searchAttributes = Api.Common.V1.SearchAttributes(searchAttributes).indexedFields
        }

        if !continueAsNewError.headers.isEmpty {
            self.headers = continueAsNewError.headers
        }
    }
}
