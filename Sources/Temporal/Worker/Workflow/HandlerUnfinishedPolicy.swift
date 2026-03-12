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

/// Policy defining actions taken when a workflow exits while update or signal handlers are still
/// running.
///
/// The workflow exit may be due to successful return, failure, cancellation, or continue-as-new.
public struct HandlerUnfinishedPolicy: Sendable, Equatable {
    package enum Kind: Sendable, Equatable {
        case warnAndAbandon
        case abandon
    }

    package let kind: Kind

    private init(_ kind: Kind) {
        self.kind = kind
    }

    /// Log a warning when the workflow exits with running handlers.
    ///
    /// This is the default policy. When the workflow completes while handlers are still running,
    /// a warning will be logged to help identify potentially interrupted work.
    public static let warnAndAbandon = HandlerUnfinishedPolicy(.warnAndAbandon)

    /// Silently abandon running handlers when the workflow exits.
    ///
    /// Use this policy when it is expected and acceptable for the handler to be interrupted
    /// by workflow completion.
    public static let abandon = HandlerUnfinishedPolicy(.abandon)
}
