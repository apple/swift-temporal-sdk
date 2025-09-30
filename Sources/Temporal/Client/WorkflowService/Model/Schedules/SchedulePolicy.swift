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

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// Execution policies that control schedule behavior during various operational scenarios.
public struct SchedulePolicy: Hashable, Sendable {
    /// The policy for handling overlapping action executions.
    public var overlap: ScheduleOverlapPolicy

    /// The time window for executing missed actions after server unavailability.
    public var catchupWindow: Duration

    /// Controls whether the schedule automatically pauses when actions fail or time out.
    public var pauseOnFailure: Bool

    /// Creates a comprehensive schedule execution policy with specified behavior controls.
    ///
    /// - Parameters:
    ///   - overlap: Policy for handling concurrent action executions.
    ///   - catchupWindow: Time window for executing missed actions after downtime.
    ///   - pauseOnFailure: Whether to automatically pause the schedule on action failures.
    public init(
        overlap: ScheduleOverlapPolicy = .skip,
        catchupWindow: Duration = .seconds(365 * 24 * 60 * 60),
        pauseOnFailure: Bool = false
    ) {
        self.overlap = overlap
        self.catchupWindow = catchupWindow
        self.pauseOnFailure = pauseOnFailure
    }
}

/// Overlap policies that determine concurrent execution behavior for scheduled actions.
public enum ScheduleOverlapPolicy: CustomStringConvertible, Hashable, Sendable {
    /// Skip new actions when previous actions are still executing.
    case skip

    /// Buffer exactly one action to execute after the current action completes.
    case bufferOne

    /// Buffer all overlapping actions for sequential execution.
    case bufferAll

    /// Cancel currently running actions before starting new ones.
    case cancelOther

    /// Terminate currently running actions and start new ones immediately.
    case terminateOther

    /// Allow all overlapping actions to run concurrently without restrictions.
    case allowAll

    public var description: String {
        switch self {
        case .skip:
            return "skip"
        case .bufferOne:
            return "buffer-one"
        case .bufferAll:
            return "buffer-all"
        case .cancelOther:
            return "cancel-other"
        case .terminateOther:
            return "terminate-other"
        case .allowAll:
            return "allow-all"
        }
    }
}
