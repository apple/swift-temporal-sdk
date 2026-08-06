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

/// Error thrown by a ``PayloadConverter`` when it cannot encode a value into a
/// payload or decode a payload into the requested type.
///
/// The ``TemporalError/message`` describes which converter failed, whether the
/// failure happened while encoding or decoding, and why, so that conversion
/// failures are actionable instead of opaque.
public struct PayloadConverterError: TemporalError {
    /// The error's message.
    public var message: String

    /// The cause of the current error.
    public var cause: (any Error)?

    /// The stack trace of the current error.
    public var stackTrace: String

    /// Creates a new payload converter error.
    ///
    /// - Parameters:
    ///   - message: The error's message.
    ///   - cause: The cause of the current error. Defaults to `nil`.
    ///   - stackTrace: The stack trace of the current error.
    public init(
        message: String,
        cause: (any Error)? = nil,
        stackTrace: String = ""
    ) {
        self.message = message
        self.cause = cause
        self.stackTrace = stackTrace
    }
}

extension PayloadConverterError {
    /// Creates an error describing a failure to encode a value into a payload.
    ///
    /// - Parameters:
    ///   - converter: The name of the converter that failed.
    ///   - reason: Why the value could not be encoded.
    ///   - cause: The underlying error, if any.
    package static func encodingFailed(
        converter: String,
        reason: String,
        cause: (any Error)? = nil
    ) -> Self {
        .init(message: "\(converter) could not encode value: \(reason).", cause: cause)
    }

    /// Creates an error describing a failure to decode a payload into a value.
    ///
    /// - Parameters:
    ///   - converter: The name of the converter that failed.
    ///   - reason: Why the payload could not be decoded.
    ///   - cause: The underlying error, if any.
    package static func decodingFailed(
        converter: String,
        reason: String,
        cause: (any Error)? = nil
    ) -> Self {
        .init(message: "\(converter) could not decode payload: \(reason).", cause: cause)
    }
}
