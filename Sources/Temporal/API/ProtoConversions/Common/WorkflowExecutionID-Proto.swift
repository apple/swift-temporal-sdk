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

extension WorkflowExecutionID {
    init(_ rawValue: Api.Common.V1.WorkflowExecution) {
        self = .init(
            workflowID: rawValue.workflowID,
            runID: rawValue.runID.isEmpty ? nil : rawValue.runID
        )
    }
}
