//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Temporal SDK open source project
//
// Copyright (c) 2026 Apple Inc. and the Swift Temporal SDK project authors
// Licensed under MIT License
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Swift Temporal SDK project authors
//
// SPDX-License-Identifier: MIT
//
//===----------------------------------------------------------------------===//

public import Foundation
internal import SwiftProtobuf

/// Represents a workflow's execution history for replay purposes.
public struct WorkflowHistory: Sendable {
    /// The workflow ID this history belongs to.
    public let id: String

    /// The history events for the workflow execution.
    public let events: [Api.History.V1.HistoryEvent]

    /// Creates a new workflow history.
    ///
    /// - Parameters:
    ///   - events: The history events for the workflow execution.
    public init(events: [Api.History.V1.HistoryEvent]) throws {
        self.events = events
        guard case let .workflowExecutionStartedEventAttributes(workflowExecutionsStartedEventAttributes) = events.first?.attributes else {
            throw ArgumentError(message: "First event not a start event")
        }
        self.id = workflowExecutionsStartedEventAttributes.workflowID
    }

    /// Creates a workflow history by parsing JSON data.
    ///
    /// This method handles JSON in the format produced by:
    /// - Temporal CLI: `temporal workflow show --output=json`
    /// - Temporal UI: Exported history download
    /// - SDK's own ``toJSON()`` method
    ///
    /// - Parameters:
    ///   - workflowID: The workflow ID.
    ///   - jsonData: The JSON data containing the history.
    /// - Returns: A ``WorkflowHistory`` instance parsed from the JSON.
    /// - Throws: ``ArgumentError`` if the JSON cannot be parsed or is invalid.
    public static func fromJSON(
        workflowID: String,
        jsonData: Data
    ) throws -> WorkflowHistory {
        // Parse using protobuf JSON decoder with ignoreUnknownFields to handle
        // CLI/UI exports that may contain extra fields
        var decodingOptions = JSONDecodingOptions()
        decodingOptions.ignoreUnknownFields = true

        let protoHistory: Api.History.V1.History
        do {
            protoHistory = try Api.History.V1.History(
                jsonUTF8Data: jsonData,
                options: decodingOptions
            )
        } catch {
            throw ArgumentError(
                message: "Failed to parse history JSON as protobuf",
                cause: error
            )
        }

        return try WorkflowHistory(
            events: Array(protoHistory.events)
        )
    }

    /// Converts this history to JSON.
    ///
    /// - Returns: A JSON string representation of the history.
    /// - Throws: An error if serialization fails.
    public func toJSON() throws -> Data {
        let history = Api.History.V1.History.with {
            $0.events = self.events
        }
        return try history.jsonUTF8Data()
    }
}
