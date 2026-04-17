//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Temporal SDK open source project
//
// Copyright (c) 2025-2026 Apple Inc. and the Swift Temporal SDK project authors
// Licensed under MIT License
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Swift Temporal SDK project authors
//
// SPDX-License-Identifier: MIT
//
//===----------------------------------------------------------------------===//

// To run a local Temporal dev server for testing these examples:
//
//   container image pull temporalio/temporal:latest
//   container run -d --name temporal -p 7233:7233 -p 8233:8233 \
//     temporalio/temporal:latest server start-dev --ip 0.0.0.0
//
// The server provides gRPC on port 7233 and the Web UI on port 8233.
// To stop: container stop temporal && container rm temporal

// snippet.hide
import Foundation
import Logging
import Temporal

// snippet.show

// snippet.base64PayloadCodec
struct Base64PayloadCodec: PayloadCodec {
    let encodingName = "application/base64"

    func encode(
        payloads: some Collection<Api.Common.V1.Payload>
    ) async throws -> [Api.Common.V1.Payload] {
        payloads.map { payload in
            var payload = payload
            payload.data = payload.data.base64EncodedData()
            payload.metadata["codec"] = Data(self.encodingName.utf8)
            return payload
        }
    }

    func decode(
        payloads: some Collection<Api.Common.V1.Payload>
    ) async throws -> [Api.Common.V1.Payload] {
        try payloads.map { payload in
            guard let decodedData = Data(base64Encoded: payload.data) else {
                throw DecodingError.dataCorrupted(
                    .init(codingPath: [], debugDescription: "Invalid Base64 data")
                )
            }
            var metadata = payload.metadata
            metadata.removeValue(forKey: "codec")
            return Api.Common.V1.Payload.with {
                $0.data = decodedData
                $0.metadata = metadata
            }
        }
    }
}
// snippet.end

// snippet.hide
// snippet.show

// snippet.workerWithCodec
let dataConverter = DataConverter(
    payloadConverter: DefaultPayloadConverter(),
    failureConverter: DefaultFailureConverter(),
    payloadCodec: Base64PayloadCodec()
)

// snippet.hide
let logger = Logger(label: "snippet")
// snippet.show
let worker = try TemporalWorker(
    configuration: .init(
        namespace: "default",
        taskQueue: "my-task-queue",
        instrumentation: .init(serverHostname: "localhost"),
        dataConverter: dataConverter
    ),
    target: .ipv4(address: "127.0.0.1", port: 7233),
    transportSecurity: .plaintext,
    logger: logger
)
// snippet.end

// snippet.compositePayloadConverter
let customConverter = CompositePayloadConverter(
    BinaryNilPayloadConverter(),
    BinaryPayloadConverter(),
    JSONProtobufPayloadConverter(),
    JSONPayloadConverter()
)

let customDataConverter = DataConverter(
    payloadConverter: customConverter,
    failureConverter: DefaultFailureConverter()
)
// snippet.end
