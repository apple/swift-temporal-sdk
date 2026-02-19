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

extension WorkflowExecutionStatus {
    init(temporalAPIWorkflowExecutionStatus: Api.Enums.V1.WorkflowExecutionStatus) {
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
        case .paused:
            self = .paused
        case .UNRECOGNIZED:
            fatalError("Unknown status send back by the temporal server")
        }
    }
}
