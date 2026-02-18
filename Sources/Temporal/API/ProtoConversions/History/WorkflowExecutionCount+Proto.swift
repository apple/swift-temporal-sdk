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

extension WorkflowExecutionCount {
    init(_ rawValue: Api.Workflowservice.V1.CountWorkflowExecutionsResponse) {
        self.count = Int(rawValue.count)
        self.groups = rawValue.groups.map { .init($0) }
    }
}

extension WorkflowExecutionCount.AggregationGroup {
    init(_ rawValue: Api.Workflowservice.V1.CountWorkflowExecutionsResponse.AggregationGroup) {
        count = Int(rawValue.count)
        values = rawValue.groupValues
            .lazy
            .compactMap { try? SearchAttributeCollection.StorageValue.convertPayload($0) }
            .map { $0.value }
    }
}
