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

extension WorkflowExecutionStatus {
    init(temporalAPIWorkflowExecutionStatus: Temporal_Api_Enums_V1_WorkflowExecutionStatus) {
        switch temporalAPIWorkflowExecutionStatus {
        case .unspecified:
            fatalError("Internal inconsistency: We should never hit this")
        case .running:
            self = .running
        case .completed:
            self = .completed
        case .failed:
            self = .failed
        case .canceled:
            self = .canceled
        case .terminated:
            self = .terminated
        case .continuedAsNew:
            self = .continuedAsNew
        case .timedOut:
            self = .timedOut
        case .UNRECOGNIZED:
            fatalError("Unknown status send back by the temporal server")
        }
    }
}
