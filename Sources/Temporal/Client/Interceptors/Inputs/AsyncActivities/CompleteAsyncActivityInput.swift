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

import struct Foundation.Data

/// Input parameters for completing an async activity in client interceptors.
public struct CompleteAsyncActivityInput<Result: Sendable>: Sendable {
    /// Activity to complete.
    public var activity: AsyncActivityHandle.Reference
    /// Result payload.
    public var result: Result?
    /// Options passed in to complete.
    public var options: AsyncActivityCompleteOptions?
    /// Data converter to use.
    public var dataConverter: DataConverter

    /// Create input parameters for completing an async activity in client interceptors.
    ///
    /// - Parameters:
    ///   - activity: Activity to complete.
    ///   - result: Result payload.
    ///   - options: Options passed in to complete.
    ///   - dataConverter: Data converter to use.
    public init(
        activity: AsyncActivityHandle.Reference,
        result: Result? = nil,
        options: AsyncActivityCompleteOptions? = nil,
        dataConverter: DataConverter
    ) {
        self.activity = activity
        self.result = result
        self.options = options
        self.dataConverter = dataConverter
    }
}
