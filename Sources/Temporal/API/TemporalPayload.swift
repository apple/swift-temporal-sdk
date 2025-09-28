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

/// Struct representing binary data such as input or output from activities or workflows.
///
/// Payloads also contain metadata that describe their data type or other parameters for use by custom encoders/converters.
public struct TemporalPayload: Hashable, Sendable {
    /// The payload's data.
    public var data: [UInt8]

    /// The payloads metadata.
    public var metadata: [String: [UInt8]]

    /// Initializes a new temporal payload.
    ///
    /// - Parameters:
    ///   - data: The payload's data.
    ///   - metadata: The payload's metadata.
    public init(
        data: [UInt8],
        metadata: [String: [UInt8]]
    ) {
        self.data = data
        self.metadata = metadata
    }
}
