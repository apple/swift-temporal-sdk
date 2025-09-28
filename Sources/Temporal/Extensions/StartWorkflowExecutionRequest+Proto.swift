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

extension Temporal_Api_Workflowservice_V1_StartWorkflowExecutionRequest {
    package init(
        namespace: String,
        identity: String,
        requestID: String,
        workflowTypeName: String,
        workflowOptions: WorkflowOptions,
        dataConverter: DataConverter,
        headers: [String: TemporalPayload],
        inputs: [TemporalPayload]
    ) async throws {
        self = .with {
            $0.namespace = namespace
            $0.workflowID = workflowOptions.id
            $0.workflowType.name = workflowTypeName
            $0.taskQueue.name = workflowOptions.taskQueue
            $0.identity = identity
            $0.requestID = requestID
            $0.workflowIDReusePolicy = .init(workflowIDReusePolicy: workflowOptions.idReusePolicy)
            $0.workflowIDConflictPolicy = .init(workflowIDConflictPolicy: workflowOptions.idConflictPolicy)
            $0.input = .with {
                $0.payloads = inputs.map { .init(temporalPayload: $0) }
            }
        }

        if let executionTimeOut = workflowOptions.executionTimeOut {
            self.workflowExecutionTimeout = .init(duration: executionTimeOut)
        }

        if let retryPolicy = workflowOptions.retryPolicy {
            self.retryPolicy = .init(retryPolicy: retryPolicy)
        }

        if let memo = workflowOptions.memo {
            var temporalPayloads = [String: Temporal_Api_Common_V1_Payload]()
            for (key, value) in memo {
                temporalPayloads[key] = .init(temporalPayload: try await dataConverter.convertValue(value))
            }
            self.memo = .with {
                $0.fields = temporalPayloads
            }
        }

        if let searchAttributes = workflowOptions.searchAttributes, !searchAttributes.isEmpty {
            self.searchAttributes = .init(searchAttributes)
        }

        if !headers.isEmpty {
            self.header = try await .init(headers, with: dataConverter.payloadCodec)
        }
    }
}
