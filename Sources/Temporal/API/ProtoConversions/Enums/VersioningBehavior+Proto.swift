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

extension VersioningBehavior {
    init(_ rawValue: Api.Enums.V1.VersioningBehavior) {
        self =
            switch rawValue {
            case .unspecified: .unspecified
            case .pinned: .pinned
            case .autoUpgrade: .autoUpgrade
            case .UNRECOGNIZED(let value):
                fatalError("Unexpected value \(value) for VersioningBehavior")
            }
    }
}
