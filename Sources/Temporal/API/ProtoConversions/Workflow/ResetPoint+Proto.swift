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

import SwiftProtobuf

extension ResetPoint {
    init(_ rawValue: Temporal_Api_Workflow_V1_ResetPointInfo) {
        self = .init(
            buildID: rawValue.buildID.isEmpty ? nil : rawValue.buildID,
            binaryChecksum: rawValue.binaryChecksum.isEmpty ? nil : rawValue.binaryChecksum,
            runID: rawValue.runID,
            firstWorkflowTaskCompletedID: Int(rawValue.firstWorkflowTaskCompletedID),
            createTime: rawValue.hasCreateTime ? rawValue.createTime.date : nil,
            expireTime: rawValue.hasExpireTime ? rawValue.expireTime.date : nil,
            isResettable: rawValue.resettable
        )
    }
}
