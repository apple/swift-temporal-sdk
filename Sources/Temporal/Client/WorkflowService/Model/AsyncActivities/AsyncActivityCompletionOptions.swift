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

import struct GRPCCore.CallOptions

/// Options for completing an async activity.
public struct AsyncActivityCompleteOptions: Sendable {
    /// Optional gRPC call options for customizing the description request.
    public var callOptions: CallOptions?

    /// Create options for completing an async activity.
    ///
    /// - Parameters:
    ///   - callOptions: Optional gRPC call options for customizing the request.
    public init(
        callOptions: CallOptions? = nil
    ) {
        self.callOptions = callOptions
    }
}
