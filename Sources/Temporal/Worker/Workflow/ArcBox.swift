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

/// A reference-counted box that holds a value by reference.
///
/// `ArcBox` provides shared mutable state through reference semantics. When a struct
/// containing an `ArcBox` is copied, all copies share the same underlying value.
final class ArcBox<Value>: @unchecked Sendable {
    /// The boxed value.
    var value: Value

    /// Creates a new box with the given value.
    ///
    /// - Parameter value: The value to box.
    init(_ value: Value) {
        self.value = value
    }

    /// Reads the value through a closure.
    ///
    /// - Parameter body: A closure that receives the value.
    /// - Returns: The value returned by the closure.
    func withValue<R>(_ body: (Value) -> R) -> R {
        body(value)
    }

    /// Mutates the value through a closure.
    ///
    /// - Parameter body: A closure that receives a mutable reference to the value.
    func withMutableValue(_ body: (inout Value) -> Void) {
        body(&value)
    }

    /// Mutates the value through a closure and returns a result.
    ///
    /// - Parameter body: A closure that receives a mutable reference to the value.
    /// - Returns: The value returned by the closure.
    func withMutableValue<R>(_ body: (inout Value) -> R) -> R {
        body(&value)
    }
}
