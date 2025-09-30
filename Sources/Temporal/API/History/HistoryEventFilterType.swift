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

/// The kind of events to filter for when fetching.
public enum HistoryEventFilterType: CustomStringConvertible, Hashable, Sendable {
    case allEvent
    case closeEvent

    public var description: String {
        switch self {
        case .allEvent:
            return "allEvent"
        case .closeEvent:
            return "closeEvent"
        }
    }
}
