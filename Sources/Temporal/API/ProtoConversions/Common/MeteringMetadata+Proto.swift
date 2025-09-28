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

extension MeteringMetadata {
    init(_ rawValue: Temporal_Api_Common_V1_MeteringMetadata) {
        self = .init(
            nonfirstLocalActivityExecutionAttempts: Int(rawValue.nonfirstLocalActivityExecutionAttempts)
        )
    }
}
