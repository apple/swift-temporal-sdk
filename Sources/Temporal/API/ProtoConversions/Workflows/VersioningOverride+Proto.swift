//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Temporal SDK open source project
//
// Copyright (c) 2026 Apple Inc. and the Swift Temporal SDK project authors
// Licensed under MIT License
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Swift Temporal SDK project authors
//
// SPDX-License-Identifier: MIT
//
//===----------------------------------------------------------------------===//

import SwiftProtobuf

extension Api.Workflow.V1.VersioningOverride {
    package init(_ override: VersioningOverride) {
        self.init()
        switch override.kind {
        case .pinned(let deploymentVersion):
            var pinnedOverride = PinnedOverride()
            pinnedOverride.behavior = .pinned
            pinnedOverride.version = .with {
                $0.deploymentName = deploymentVersion.deploymentName
                $0.buildID = deploymentVersion.buildId
            }
            self.override = .pinned(pinnedOverride)
        case .autoUpgrade:
            self.override = .autoUpgrade(true)
        }
    }
}
