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

import SwiftProtobuf

import struct Foundation.Data

extension TemporalPayload {
    init(temporalAPIPayload: Temporal_Api_Common_V1_Payload) {
        self.init(
            data: Array(temporalAPIPayload.data),
            metadata: temporalAPIPayload.metadata.mapValues { Array($0) }
        )
    }
}

extension Temporal_Api_Common_V1_Payload {
    package init(temporalPayload: TemporalPayload) {
        self = Self.with {
            $0.data = Data(temporalPayload.data)
            $0.metadata = temporalPayload.metadata.mapValues { Data($0) }
        }
    }
}
