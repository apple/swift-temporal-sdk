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

extension ParentClosePolicy {
    init(_ rawValue: Temporal_Api_Enums_V1_ParentClosePolicy) {
        self =
            switch rawValue {
            case .unspecified: .none
            case .terminate: .terminate
            case .abandon: .abandon
            case .requestCancel: .requestCancel
            case .UNRECOGNIZED(let value):
                fatalError("Unexpected value \(value) for ParentClosePolicy")
            }
    }
}

extension Coresdk_ChildWorkflow_ParentClosePolicy {
    init(parentClosePolicy: ParentClosePolicy) {
        switch parentClosePolicy {
        case .none:
            self = .unspecified
        case .terminate:
            self = .terminate
        case .abandon:
            self = .abandon
        case .requestCancel:
            self = .requestCancel
        }
    }
}
