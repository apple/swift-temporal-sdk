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

public enum ContinueAsNewInitiator: Hashable, Sendable {
    case unspecified

    /// The workflow itself requested to continue as new
    case workflow

    /// The workflow continued as new because it is retrying
    case retry

    /// The workflow continued as new because cron has triggered a new execution
    case cronSchedule
}
