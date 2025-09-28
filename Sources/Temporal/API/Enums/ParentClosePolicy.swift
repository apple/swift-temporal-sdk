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

/// How a workflow child will be handled when its parent workflow closes.
// TODO: Revisit this before major regarding extensible enums
public enum ParentClosePolicy: Hashable, Sendable {
    /// No value set and will internally default. This should not be used.
    case none
    /// Child workflow will be terminated.
    case terminate
    /// Child workflow will do nothing.
    case abandon
    /// Cancellation will be requested on the child workflow.
    case requestCancel

    var description: String {
        switch self {
        case .none: "none"
        case .terminate: "terminate"
        case .abandon: "abandon"
        case .requestCancel: "requestCancel"
        }
    }
}
