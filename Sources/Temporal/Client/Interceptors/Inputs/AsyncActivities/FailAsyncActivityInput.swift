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

/// Input parameters for failing an async activity in client interceptors.
public struct FailAsyncActivityInput: Sendable {
    /// Activity to fail.
    public var activity: AsyncActivityHandle.Reference
    /// Error to report.
    public var error: Error
    /// Options passed in to fail.
    public var options: AsyncActivityFailOptions?
    /// Data converter to use.
    public var dataConverter: DataConverter

    /// Create input parameters for failing an async activity in client interceptors.
    ///
    /// - Parameters:
    ///   - activity: Activity to fail.
    ///   - error: Error to report.
    ///   - options: Options passed in to fail.
    ///   - dataConverter: Data converter to use.
    public init(
        activity: AsyncActivityHandle.Reference,
        error: Error,
        options: AsyncActivityFailOptions? = nil,
        dataConverter: DataConverter
    ) {
        self.activity = activity
        self.error = error
        self.options = options
        self.dataConverter = dataConverter
    }
}
