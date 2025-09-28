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

extension VersioningOverride {
    init(_ rawValue: Temporal_Api_Workflow_V1_VersioningOverride) {
        self = .init(
            behavior: .init(rawValue.behavior),
            deployment: rawValue.hasDeployment ? .init(rawValue.deployment) : nil,
            pinnedVersion: rawValue.pinnedVersion.isEmpty ? nil : rawValue.pinnedVersion
        )
    }
}
