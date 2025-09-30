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

/// Input parameters for heartbeats in an async activity in client interceptors.
public struct HeartbeatAsyncActivityInput: Sendable {
    /// Async activity to heartbeat.
    public var activity: AsyncActivityHandle.Reference
    /// Options passed in to heartbeat.
    public var options: AsyncActivityHeartbeatOptions?
    /// Data converter to use.
    public var dataConverter: DataConverter

    /// Creates input parameters for heartbeating async activities in client interceptors.
    ///
    /// - Parameters:
    ///   - activity: Async activity to heartbeat.
    ///   - options: Options passed in to heartbeat.
    ///   - dataConverter: Data converter to use.
    public init(
        activity: AsyncActivityHandle.Reference,
        options: AsyncActivityHeartbeatOptions? = nil,
        dataConverter: DataConverter
    ) {
        self.activity = activity
        self.options = options
        self.dataConverter = dataConverter
    }
}
