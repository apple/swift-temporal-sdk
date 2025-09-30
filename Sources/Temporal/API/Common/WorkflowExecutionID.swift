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

public struct WorkflowExecutionID: Hashable, Sendable {
    public var workflowID: String
    public var runID: String?

    public init(workflowID: String, runID: String? = nil) {
        self.workflowID = workflowID
        self.runID = runID
    }
}
