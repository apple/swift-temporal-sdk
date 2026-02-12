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

import Temporal

/// A simple error for testing that does not conform to `TemporalFailureError`.
struct TestError: Error {}

/// A test error that conforms to `TemporalFailureError`.
struct TestFailureError: TemporalFailureError {
    var message: String = "TestFailureError"
    var cause: (any Error)?
    var stackTrace: String = ""
}
