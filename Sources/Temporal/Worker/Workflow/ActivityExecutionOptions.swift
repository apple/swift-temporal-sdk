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

import struct SwiftProtobuf.Google_Protobuf_Timestamp

enum ActivityExecutionOptions {
    case remote(ActivityOptions)
    case local(LocalActivityOptions, attempt: UInt32? = nil, originalScheduleTime: Google_Protobuf_Timestamp? = nil)

    var isLocal: Bool {
        switch self {
        case .remote: false
        case .local: true
        }
    }

    func withBackoff(_ backoff: Coresdk_ActivityResult_DoBackoff) -> Self {
        switch self {
        case .remote:
            fatalError("A remote activity should not receive a backoff.")
        case let .local(options, _, _):
            return .local(options, attempt: backoff.attempt, originalScheduleTime: backoff.originalScheduleTime)
        }
    }
}
