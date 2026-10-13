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

/// The requirements shared by ``ClientPlugin`` and ``WorkerPlugin``.
///
/// Conform to ``ClientPlugin`` or ``WorkerPlugin`` rather than to this protocol directly. A type
/// that conforms to both gets a single ``name``, declared here.
///
/// - Important: This is currently experimental and may be removed or changed in the future.
public protocol TemporalPlugin: Sendable {
    /// A human-readable name for this plugin, used in diagnostics.
    ///
    /// Defaults to the conforming type's name. Provide your own to keep log output stable across
    /// renames of the type, or to include your organization, as in `"my-org.observability"`.
    var name: String { get }
}

extension TemporalPlugin {
    public var name: String {
        String(describing: Self.self)
    }
}
