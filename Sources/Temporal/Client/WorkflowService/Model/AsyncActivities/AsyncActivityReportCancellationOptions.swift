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

public import struct GRPCCore.CallOptions

/// Options for reporting cancellation of async activities.
public struct AsyncActivityReportCancellationOptions: Sendable {
    /// The details for the cancellation.
    public var details: [any Sendable]
    /// Optional gRPC call options for customizing the cancellation report request.
    public var callOptions: CallOptions?

    /// Creates options for reporting cancellation of async activities.
    ///
    /// - Parameters:
    ///   - details: The details for the cancellation.
    ///   - callOptions: Optional gRPC call options for customizing the request.
    public init(
        details: [any Sendable],
        callOptions: CallOptions? = nil
    ) {
        self.details = details
        self.callOptions = callOptions
    }
}
