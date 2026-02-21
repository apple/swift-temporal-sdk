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

extension HistoryEvent.Attributes {
    /// Event attributes for when a marker has been recorded.
    public struct MarkerRecorded: Hashable, Sendable {
        /// Workers use this to identify the "types" of various markers.
        ///
        /// Ex: Local activity, side effect.
        public var markerName: String

        /// Serialized information recorded in the marker.
        public var details: [String: [Api.Common.V1.Payload]]

        /// The `WORKFLOW_TASK_COMPLETED` event which this command was reported with.
        public var workflowTaskCompletedEventID: Int

        /// Headers associated with the marker.
        public var headers: [String: Api.Common.V1.Payload]

        /// Some uses of markers, like a local activity, could "fail".
        ///
        /// If they did that is recorded here.
        public var failure: TemporalFailure?

        /// Creates event attributes for when a marker has been recorded.
        public init(
            markerName: String,
            details: [String: [Api.Common.V1.Payload]] = [:],
            workflowTaskCompletedEventID: Int,
            headers: [String: Api.Common.V1.Payload] = [:],
            failure: TemporalFailure? = nil
        ) {
            self.markerName = markerName
            self.details = details
            self.workflowTaskCompletedEventID = workflowTaskCompletedEventID
            self.headers = headers
            self.failure = failure
        }
    }
}
