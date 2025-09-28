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

/// Input parameters for reporting cancellation of an async activity in client interceptors.
public struct ReportCancellationAsyncActivityInput: Sendable {
    /// Activity to report cancellation for.
    public var activity: AsyncActivityHandle.Reference
    /// Options passed in to report cancellation.
    public var options: AsyncActivityReportCancellationOptions?
    /// Data converter to use.
    public var dataConverter: DataConverter

    /// Create input parameters for reporting cancellation of an async activity in client interceptors.
    ///
    /// - Parameters:
    ///   - activity: Activity to report cancellation for.
    ///   - options: Options passed in to report cancellation.
    ///   - dataConverter: Data converter to use.
    public init(
        activity: AsyncActivityHandle.Reference,
        options: AsyncActivityReportCancellationOptions? = nil,
        dataConverter: DataConverter
    ) {
        self.activity = activity
        self.options = options
        self.dataConverter = dataConverter
    }
}
