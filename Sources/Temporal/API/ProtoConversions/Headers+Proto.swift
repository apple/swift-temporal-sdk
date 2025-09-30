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

extension Temporal_Api_Common_V1_Header {
    init(_ dictionary: [String: TemporalPayload], with payloadCodec: PayloadCodec?) async throws {
        self.fields.reserveCapacity(dictionary.count)
        for (key, value) in dictionary {
            if let payloadCodec {
                // If there is a payload codec, use it to encode the headers:
                // https://github.com/temporalio/sdk-dotnet/blob/5b15fb8523879db47c3442cf3cfc739643d1ed14/src/Temporalio/Client/TemporalClient.Workflow.cs#L840
                let payloadEncodedValue = try await payloadCodec.encode(payload: value)
                self.fields[key] = .init(temporalPayload: payloadEncodedValue)
            } else {
                self.fields[key] = .init(temporalPayload: value)
            }
        }
    }

    func decoded(with payloadCodec: PayloadCodec?) async throws -> [String: TemporalPayload] {
        var result = [String: TemporalPayload]()
        for (key, value) in self.fields {
            result[key] = try await payloadCodec?.decode(payload: .init(temporalAPIPayload: value)) ?? .init(temporalAPIPayload: value)
        }
        return result
    }
}
