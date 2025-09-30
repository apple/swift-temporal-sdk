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

extension SignalExternalWorkflowExecutionFailedCause {
    init(_ rawValue: Temporal_Api_Enums_V1_SignalExternalWorkflowExecutionFailedCause) {
        self =
            switch rawValue {
            case .unspecified: .unspecified
            case .externalWorkflowExecutionNotFound: .externalWorkflowExecutionNotFound
            case .namespaceNotFound: .namespaceNotFound
            case .signalCountLimitExceeded: .signalCountLimitExceeded
            case .UNRECOGNIZED(let value):
                fatalError("Unexpected value \(value) for SignalExternalWorkflowExecutionFailedCause")
            }
    }
}
