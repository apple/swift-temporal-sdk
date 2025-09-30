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

/// A protocol defining a container that provides activity definition instances.
///
/// Types conforming to `ActivityContainer` serve as collections of related activities
/// that can be registered together with a Temporal worker. This allows for organized
/// grouping of activities by functionality or domain.
///
/// ## Usage
///
/// ```swift
/// @ActivityContainer
/// struct PaymentActivities: ActivityContainer {
///     // Activities will be automatically discovered by the macro
/// }
/// ```
public protocol ActivityContainer: Sendable {
    /// All activity definition instances contained by this container.
    ///
    /// This property provides access to all activities that should be registered with
    /// a Temporal worker when this container is used during worker initialization.
    var allActivities: [any ActivityDefinition] { get }
}
