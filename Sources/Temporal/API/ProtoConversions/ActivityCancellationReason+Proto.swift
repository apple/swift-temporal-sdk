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

extension ActivityCancellationReason {
    init(temporalAPICancelReason: Coresdk_ActivityTask_ActivityCancelReason) {
        switch temporalAPICancelReason {
        case .notFound:
            self = .goneFromServer
        case .cancelled:
            self = .serverRequest
        case .timedOut:
            self = .timeout
        case .workerShutdown:
            self = .workerShutdown
        case .paused:
            self = .paused
        case .reset:
            self = .reset
        case .UNRECOGNIZED:
            self = .unknown
        }
    }
}
