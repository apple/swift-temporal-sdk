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

/// Error protocol for all custom errors thrown by the Temporal library.
public protocol TemporalError: Error, CustomStringConvertible {
    /// The error's message.
    var message: String { get set }

    /// The cause of the current error.
    var cause: (any Error)? { get set }

    /// The stack trace of the current error.
    var stackTrace: String { get set }
}

extension TemporalError {
    public var description: String {
        self.message + (self.cause.map { " (cause: \($0))" } ?? "")
    }
}
