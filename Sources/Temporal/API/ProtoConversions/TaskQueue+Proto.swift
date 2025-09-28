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

extension TaskQueue {
    init(_ rawValue: Temporal_Api_Taskqueue_V1_TaskQueue) {
        self = .init(
            name: rawValue.name,
            kind: .init(rawValue.kind)
        )
    }
}

extension TaskQueue.Kind {
    init(_ rawValue: Temporal_Api_Enums_V1_TaskQueueKind) {
        self =
            switch rawValue {
            case .unspecified: .unspecified
            case .normal: .normal
            case .sticky: .sticky
            case .UNRECOGNIZED(let value): fatalError("Unexpected value \(value) for TaskQueue.Kind")
            }
    }
}
