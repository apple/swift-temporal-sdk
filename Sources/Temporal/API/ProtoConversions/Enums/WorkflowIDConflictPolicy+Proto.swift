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

extension WorkflowIDConflictPolicy {
    package init(_ rawValue: Temporal_Api_Enums_V1_WorkflowIdConflictPolicy) {
        self =
            switch rawValue {
            case .unspecified: .unspecified
            case .fail: .fail
            case .useExisting: .useExisting
            case .terminateExisting: .terminateExisting
            case .UNRECOGNIZED:
                fatalError("Unexpected value \(rawValue) for WorkflowIDConflictPolicy")
            }
    }
}

extension Temporal_Api_Enums_V1_WorkflowIdConflictPolicy {
    init(workflowIDConflictPolicy: WorkflowIDConflictPolicy) {
        switch workflowIDConflictPolicy {
        case .unspecified:
            self = .unspecified
        case .fail:
            self = .fail
        case .useExisting:
            self = .useExisting
        case .terminateExisting:
            self = .terminateExisting
        }
    }
}
