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

import Foundation
import SwiftProtobuf

extension Coresdk.ActivityTaskCompletion {
    init(taskToken: Data, result: ActivityExecutionResult) {
        self = Self.with {
            $0.taskToken = taskToken

            switch result {
            case .completed(let payload):
                $0.result.completed.result = payload
            case .failed(let failure):
                $0.result.failed.failure = failure
            case .cancelled(let failure):
                $0.result.cancelled.failure = failure
            case .willCompleteAsync:
                $0.result.willCompleteAsync = .init()
            }
        }
    }
}
