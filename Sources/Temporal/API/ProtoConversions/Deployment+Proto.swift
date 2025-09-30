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

extension Deployment {
    init(_ rawValue: Temporal_Api_Deployment_V1_Deployment) {
        self = .init(seriesName: rawValue.seriesName, buildID: rawValue.buildID)
    }
}
