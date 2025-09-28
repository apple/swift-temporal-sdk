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

/// History events are the method by which Temporal SDKs advance (or recreate) workflow state.
public struct HistoryEvent: Hashable, Sendable {
    public var attributes: Attributes?
    public var eventType: EventType
}
