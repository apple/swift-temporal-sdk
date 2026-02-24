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

/// A payload converter that decodes/encodes only from/to a single encoding kind.
public protocol EncodingPayloadConverter: PayloadConverter {
    /// The name of the encoding.
    static var encoding: String { get }
}

extension EncodingPayloadConverter {
    internal func createPayload(
        for data: some Sequence<UInt8>,
        additionalMetadata: [String: Data] = [:]
    ) -> Api.Common.V1.Payload {
        let encodingData = Data(Self.encoding.utf8)
        var metadata = additionalMetadata
        if metadata[Encodings.encodingKey] == nil {
            metadata[Encodings.encodingKey] = encodingData
        }
        return .with {
            $0.data = Data(data)
            $0.metadata = metadata
        }
    }
}
