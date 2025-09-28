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

extension Coresdk_Common_VersioningIntent {
    init(versioningIntent: VersioningIntent) {
        switch versioningIntent {
        case .unspecified:
            self = .unspecified
        case .compatible:
            self = .compatible
        case .currentDefault:
            self = .default
        }
    }
}
