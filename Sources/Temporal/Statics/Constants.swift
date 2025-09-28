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

@preconcurrency import CConstants  // preconcurrency necessary as we otherwise cannot refer to the C-exposed const

package enum Constants {
    /// The version of the Swift Temporal SDK derived from the git tag / commit.
    package static let sdkVersion = String(cString: SwiftTemporalSdkVersion)
}
