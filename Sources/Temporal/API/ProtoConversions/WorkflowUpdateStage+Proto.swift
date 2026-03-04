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

extension Api.Enums.V1.UpdateWorkflowExecutionLifecycleStage {
    init(_ workflowUpdateStage: WorkflowUpdateStage) {
        switch workflowUpdateStage {
        case .admitted:
            self = .admitted
        case .accepted:
            self = .accepted
        case .completed:
            self = .completed
        }
    }
}
