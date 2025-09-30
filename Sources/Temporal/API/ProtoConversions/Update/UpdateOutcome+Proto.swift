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

extension UpdateOutcome {
    init(_ rawValue: Temporal_Api_Update_V1_Outcome) {
        self =
            switch rawValue.value {
            case .failure(let failure): .failure(.init(temporalAPIFailure: failure))
            case .success(let value): .success(value.payloads.map { .init(temporalAPIPayload: $0) })
            case .none: fatalError("Unexpected nil value decoding UpdateOutcome.")
            }
    }
}
