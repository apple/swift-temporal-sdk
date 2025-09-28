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

import struct Foundation.Date

public struct ResetPoint: Hashable, Sendable {
    /// Worker build id.
    public var buildID: String?

    /// A worker binary version identifier (deprecated).
    public var binaryChecksum: String?

    /// The first run ID in the execution chain that was touched by this worker build.
    public var runID: String

    /// Event ID of the first WorkflowTaskCompleted event processed by this worker build.
    public var firstWorkflowTaskCompletedID: Int

    public var createTime: Date?

    /// The time that the run is deleted due to retention.
    public var expireTime: Date?

    /// False if the reset point has pending childWFs/reqCancels/signalExternals.
    public var isResettable: Bool

    public init(
        buildID: String? = nil,
        binaryChecksum: String? = nil,
        runID: String,
        firstWorkflowTaskCompletedID: Int,
        createTime: Date? = nil,
        expireTime: Date? = nil,
        isResettable: Bool
    ) {
        self.buildID = buildID
        self.binaryChecksum = binaryChecksum
        self.runID = runID
        self.firstWorkflowTaskCompletedID = firstWorkflowTaskCompletedID
        self.createTime = createTime
        self.expireTime = expireTime
        self.isResettable = isResettable
    }
}
