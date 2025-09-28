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

extension WorkflowTaskCompletedMetadata {
    init(_ rawValue: Temporal_Api_Sdk_V1_WorkflowTaskCompletedMetadata) {
        self = .init(
            coreUsedFlags: rawValue.coreUsedFlags,
            langUsedFlags: rawValue.langUsedFlags,
            sdkName: rawValue.sdkName.isEmpty ? nil : rawValue.sdkName,
            sdkVersion: rawValue.sdkVersion.isEmpty ? nil : rawValue.sdkVersion
        )
    }
}
