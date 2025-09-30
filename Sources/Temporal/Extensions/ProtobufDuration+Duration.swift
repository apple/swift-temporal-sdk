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

extension Duration {
    init(protobufDuration: Google_Protobuf_Duration) {
        self.init(
            secondsComponent: protobufDuration.seconds,
            attosecondsComponent: Int64(protobufDuration.nanos * 1_000_000_000)
        )
    }
}

extension Google_Protobuf_Duration {
    init(duration: Duration) {
        self = Self.with {
            $0.seconds = duration.components.seconds
            $0.nanos = Int32(duration.components.attoseconds / 1_000_000_000)
        }
    }
}
