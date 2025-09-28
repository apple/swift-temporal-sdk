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

import Temporal

extension WorkflowHandle {
    func with(id workflowID: String) -> WorkflowHandle {
        WorkflowHandle(
            untypedHandle: UntypedWorkflowHandle(
                interceptor: self.untypedHandle.interceptor,
                id: workflowID,
                runID: self.runID,
                resultRunID: self.resultRunID,
                firstExecutionRunID: self.firstExecutionRunID
            )
        )
    }

    func with(resultRunID: String?) -> WorkflowHandle {
        WorkflowHandle(
            untypedHandle: UntypedWorkflowHandle(
                interceptor: self.untypedHandle.interceptor,
                id: self.id,
                runID: self.runID,
                resultRunID: resultRunID,
                firstExecutionRunID: self.firstExecutionRunID
            )
        )
    }

    func with<W: WorkflowDefinition>(workflowType: W.Type = W.self) -> WorkflowHandle<W> {
        WorkflowHandle<W>(
            untypedHandle: UntypedWorkflowHandle(
                interceptor: self.untypedHandle.interceptor,
                id: self.id,
                runID: self.runID,
                resultRunID: self.resultRunID,
                firstExecutionRunID: self.firstExecutionRunID
            )
        )
    }
}
