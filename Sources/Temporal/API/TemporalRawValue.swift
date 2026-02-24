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

/// A raw value that is already decoded but not converted.
public struct TemporalRawValue: Hashable, Sendable {
    /// The raw payload value.
    public let payload: Api.Common.V1.Payload

    /// Initialized a new temporal raw value.
    /// - Parameter payload: The raw value's payload.
    public init(_ payload: Api.Common.V1.Payload) {
        self.payload = payload
    }
}
