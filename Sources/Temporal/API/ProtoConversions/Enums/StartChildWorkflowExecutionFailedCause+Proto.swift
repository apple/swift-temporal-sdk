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

extension StartChildWorkflowExecutionFailedCause {
    init(_ rawValue: Temporal_Api_Enums_V1_StartChildWorkflowExecutionFailedCause) {
        self =
            switch rawValue {
            case .unspecified: .unspecified
            case .workflowAlreadyExists: .workflowAlreadyExists
            case .namespaceNotFound: .namespaceNotFound
            case .UNRECOGNIZED(let value):
                fatalError("Unexpected value \(value) for StartChildWorkflowExecutionFailedCause")
            }
    }
}
