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

/// Input parameters for pausing workflow schedules in client interceptors.
public struct PauseScheduleInput: Sendable {
    /// The unique identifier of the schedule to pause.
    public var id: String

    /// Optional note documenting the reason for pausing the schedule.
    public var note: String?

    /// Optional gRPC call options for customizing the pause request.
    public var callOptions: CallOptions?

    /// Creates a new pause schedule input with the specified parameters.
    ///
    /// - Parameters:
    ///   - id: The unique identifier of the schedule to pause.
    ///   - note: Optional note documenting the reason for pausing the schedule.
    ///   - callOptions: Optional gRPC call options for customizing the request.
    public init(id: String, note: String? = nil, callOptions: CallOptions? = nil) {
        self.id = id
        self.note = note
        self.callOptions = callOptions
    }
}
