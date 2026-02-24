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
import Temporal

struct Base64PayloadCodec: PayloadCodec {
    let encodingName = "application/base64"

    func encode(payload: Api.Common.V1.Payload) async throws -> Api.Common.V1.Payload {
        var payload = payload
        payload.data = payload.data.base64EncodedData()
        payload.metadata["codec"] = Data(self.encodingName.utf8)
        return payload
    }

    func decode(payload: Api.Common.V1.Payload) async throws -> Api.Common.V1.Payload {
        guard let decodedData = Data(base64Encoded: payload.data) else {
            fatalError()
        }
        var metadata = payload.metadata
        metadata.removeValue(forKey: "codec")
        return Api.Common.V1.Payload.with {
            $0.data = decodedData
            $0.metadata = metadata
        }
    }
}
