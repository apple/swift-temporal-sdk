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

extension TimeoutType {
    init(_ rawValue: Api.Enums.V1.TimeoutType) {
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

extension Api.Enums.V1.TimeoutType {
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
