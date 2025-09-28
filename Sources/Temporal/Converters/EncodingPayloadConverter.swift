//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Temporal SDK open source project
//
// Copyright (c) 2025 Apple Inc. and the Swift Temporal SDK project authors
// Licensed under MIT License
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Swift Cassandra Client project authors
//
// SPDX-License-Identifier: MIT
//
//===----------------------------------------------------------------------===//

/// A payload converter that decodes/encodes only from/to a single encoding kind.
public protocol EncodingPayloadConverter: PayloadConverter {
    /// The name of the encoding.
    static var encoding: String { get }
}

extension EncodingPayloadConverter {
    internal func createPayload(
        for data: some Sequence<UInt8>,
        additionalMetadata: [String: [UInt8]] = [:]
    ) -> TemporalPayload {
        let metadata = additionalMetadata.merging([Encodings.encodingKey: Array(Self.encoding.utf8)]) { clientSpecified, _ in clientSpecified }
        return .init(data: Array(data), metadata: metadata)
    }
}
