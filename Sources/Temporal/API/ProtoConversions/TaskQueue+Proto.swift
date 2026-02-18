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

extension TaskQueue {
    init(_ rawValue: Api.Taskqueue.V1.TaskQueue) {
        self = .init(
            name: rawValue.name,
            kind: .init(rawValue.kind)
        )
    }
}

extension TaskQueue.Kind {
    init(_ rawValue: Api.Enums.V1.TaskQueueKind) {
        self =
            switch rawValue {
            case .unspecified: .unspecified
            case .normal: .normal
            case .sticky: .sticky
            case .UNRECOGNIZED(let value): fatalError("Unexpected value \(value) for TaskQueue.Kind")
            }
    }
}
