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

extension UpdateInput {
    init(_ rawValue: Temporal_Api_Update_V1_Input) {
        self = .init(
            headers: rawValue.header.fields.mapValues { .init(temporalAPIPayload: $0) },
            name: rawValue.name,
            arguments: rawValue.args.payloads.map { .init(temporalAPIPayload: $0) }
        )
    }
}
