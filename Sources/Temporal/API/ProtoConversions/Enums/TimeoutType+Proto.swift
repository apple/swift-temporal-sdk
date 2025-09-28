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

extension TimeoutType {
    init(_ rawValue: Temporal_Api_Enums_V1_TimeoutType) {
        self =
            switch rawValue {
            case .unspecified: .unspecified
            case .startToClose: .startToClose
            case .scheduleToClose: .scheduleToClose
            case .scheduleToStart: .scheduleToStart
            case .heartbeat: .heartbeat
            case .UNRECOGNIZED(let value):
                fatalError("Unexpected value \(value) for TimeoutType")
            }
    }
}

extension Temporal_Api_Enums_V1_TimeoutType {
    init(_ type: TimeoutType) {
        self =
            switch type {
            case .unspecified: .unspecified
            case .startToClose: .startToClose
            case .scheduleToClose: .scheduleToClose
            case .scheduleToStart: .scheduleToStart
            case .heartbeat: .heartbeat
            }
    }
}
