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
import Temporal

struct FailingPayloadCodec: PayloadCodec {
    func encode(payload: Api.Common.V1.Payload) async throws -> Api.Common.V1.Payload {
        throw CancellationError()
    }

    func decode(payload: Api.Common.V1.Payload) async throws -> Api.Common.V1.Payload {
        throw CancellationError()
    }
}
