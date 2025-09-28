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

extension WorkflowIDReusePolicy {
    package init(_ rawValue: Temporal_Api_Enums_V1_WorkflowIdReusePolicy) {
        self =
            switch rawValue {
            case .unspecified: .unspecified
            case .allowDuplicate: .allowDuplicate
            case .allowDuplicateFailedOnly: .allowDuplicateFailedOnly
            case .rejectDuplicate: .rejectDuplicate
            case .terminateIfRunning: .terminateIfRunning
            case .UNRECOGNIZED(let value):
                fatalError("Unexpected value \(value) for WorkflowIDReusePolicy")
            }
    }
}

extension Temporal_Api_Enums_V1_WorkflowIdReusePolicy {
    init(workflowIDReusePolicy: WorkflowIDReusePolicy) {
        switch workflowIDReusePolicy {
        case .unspecified:
            self = .unspecified
        case .allowDuplicate:
            self = .allowDuplicate
        case .allowDuplicateFailedOnly:
            self = .allowDuplicateFailedOnly
        case .rejectDuplicate:
            self = .rejectDuplicate
        case .terminateIfRunning:
            self = .terminateIfRunning
        }
    }
}
