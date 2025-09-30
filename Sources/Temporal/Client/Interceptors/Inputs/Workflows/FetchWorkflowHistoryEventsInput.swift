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

/// Input parameters for fetching workflow history events in client interceptors.
public struct FetchWorkflowHistoryEventsInput: Sendable {
    /// The unique identifier of the workflow whose history should be fetched.
    public var id: String

    /// The specific run ID of the workflow execution whose history to fetch.
    public var runID: String?

    /// Whether to wait for new events after processing all available events.
    public var waitNewEvent: Bool

    /// The types of events to include in the fetched history.
    public var eventFilterType: HistoryEventFilterType

    /// Whether to skip events that have been archived.
    public var skipArchival: Bool

    /// Optional gRPC call options for customizing the history fetch request.
    public var callOptions: CallOptions?

    /// Creates a new fetch workflow history events input with the specified parameters.
    ///
    /// - Parameters:
    ///   - id: The unique identifier of the workflow whose history should be fetched.
    ///   - runID: The specific run ID of the workflow execution whose history to fetch.
    ///   - waitNewEvent: Whether to wait for new events after processing existing ones.
    ///   - eventFilterType: The types of events to include in the fetched history.
    ///   - skipArchival: Whether to skip events that have been archived.
    ///   - callOptions: Optional gRPC call options for customizing the request.
    public init(
        id: String,
        runID: String? = nil,
        waitNewEvent: Bool,
        eventFilterType: HistoryEventFilterType,
        skipArchival: Bool,
        callOptions: CallOptions? = nil
    ) {
        self.id = id
        self.runID = runID
        self.waitNewEvent = waitNewEvent
        self.eventFilterType = eventFilterType
        self.skipArchival = skipArchival
        self.callOptions = callOptions
    }
}
