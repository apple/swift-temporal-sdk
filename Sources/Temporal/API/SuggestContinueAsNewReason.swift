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

/// Specifies why the server suggests a workflow should continue-as-new.
///
/// When the server detects that a workflow's state is growing too large,
/// it provides one or more reasons to indicate why a continue-as-new is recommended.
///
/// - Important: This is currently experimental and may be removed or changed in the future.
@nonexhaustive
public enum SuggestContinueAsNewReason: Sendable, Hashable {
    /// Unspecified reason.
    case unspecified

    /// The workflow history size in bytes is getting too large.
    case historySizeTooLarge

    /// The workflow history event count is getting too large.
    case tooManyHistoryEvents

    /// The workflow's count of completed plus in-flight updates is too large.
    case tooManyUpdates
}
