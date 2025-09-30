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

/// Input parameters for manually triggering workflow schedules in client interceptors.
public struct TriggerScheduleInput: Sendable {
    /// The unique identifier of the schedule to trigger.
    public var id: String

    /// Optional overlap policy override for this specific execution.
    public var overlap: ScheduleOverlapPolicy?

    /// Optional gRPC call options for customizing the trigger request.
    public var callOptions: CallOptions?

    /// Creates a new trigger schedule input with the specified parameters.
    ///
    /// - Parameters:
    ///   - id: The unique identifier of the schedule to trigger.
    ///   - overlap: Optional overlap policy override for this specific execution.
    ///   - callOptions: Optional gRPC call options for customizing the request.
    public init(id: String, overlap: ScheduleOverlapPolicy? = nil, callOptions: CallOptions? = nil) {
        self.id = id
        self.overlap = overlap
        self.callOptions = callOptions
    }
}
