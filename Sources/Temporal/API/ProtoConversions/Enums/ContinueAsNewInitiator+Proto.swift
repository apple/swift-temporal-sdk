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

extension ContinueAsNewInitiator {
    init(_ rawValue: Temporal_Api_Enums_V1_ContinueAsNewInitiator) {
        self =
            switch rawValue {
            case .unspecified: .unspecified
            case .workflow: .workflow
            case .retry: .retry
            case .cronSchedule: .cronSchedule
            case .UNRECOGNIZED(let value):
                fatalError("Unexpected value \(value) for ContinueAsNewInitiator")
            }
    }
}
