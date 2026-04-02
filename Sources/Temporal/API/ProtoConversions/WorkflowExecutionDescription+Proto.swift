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

extension WorkflowExecutionDescription {
    init(_ raw: Api.Workflowservice.V1.DescribeWorkflowExecutionResponse, dataConverter: DataConverter) throws {
        self.execution = try .init(raw.workflowExecutionInfo, dataConverter: dataConverter)
        self.pendingActivities = raw.pendingActivities

        let userMetadata = raw.executionConfig.userMetadata
        if userMetadata.hasSummary {
            self.staticSummary = try dataConverter.payloadConverter.convertPayload(
                userMetadata.summary,
                as: String.self
            )
        }
        if userMetadata.hasDetails {
            self.staticDetails = try dataConverter.payloadConverter.convertPayload(
                userMetadata.details,
                as: String.self
            )
        }
    }
}
