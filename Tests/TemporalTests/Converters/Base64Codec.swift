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
import Temporal

struct Base64PayloadCodec: PayloadCodec {
    let encodingName = "application/base64"

    func encode(payload: TemporalPayload) async throws -> TemporalPayload {
        var payload = payload
        payload.data = Array(Data(payload.data).base64EncodedData())
        payload.metadata["codec"] = Array(self.encodingName.utf8)
        return payload
    }

    func decode(payload: TemporalPayload) async throws -> TemporalPayload {
        guard let decodedData = Data(base64Encoded: Data(payload.data)) else {
            fatalError()
        }
        var metadata = payload.metadata
        metadata.removeValue(forKey: "codec")
        return TemporalPayload(data: Array(decodedData), metadata: metadata)
    }
}
