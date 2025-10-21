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

/// Input parameters for deleting workflow schedules in client interceptors.
public struct DeleteScheduleInput: Sendable {
    /// The unique identifier of the schedule to delete.
    public var id: String

    /// Optional gRPC call options for customizing the deletion request.
    public var callOptions: CallOptions?

    /// Creates a new delete schedule input with the specified parameters.
    ///
    /// - Parameters:
    ///   - id: The unique identifier of the schedule to delete.
    ///   - callOptions: Optional gRPC call options for customizing the request.
    public init(id: String, callOptions: CallOptions? = nil) {
        self.id = id
        self.callOptions = callOptions
    }
}
