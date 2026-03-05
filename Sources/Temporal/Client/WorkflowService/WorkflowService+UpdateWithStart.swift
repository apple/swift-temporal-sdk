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

import struct GRPCCore.CallOptions

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

extension TemporalClient.WorkflowService {
    /// The result of an update-with-start operation, containing both the workflow run ID
    /// and the update ID.
    package struct UpdateWithStartResult: Sendable {
        /// The run ID of the workflow execution.
        package let runID: String
        /// The update ID of the started update.
        package let updateID: String
    }

    /// Starts a workflow (if not already running) and sends an update to it atomically.
    ///
    /// This method uses the `ExecuteMultiOperation` RPC to bundle a start-workflow operation
    /// and an update-workflow operation into a single atomic request.
    ///
    /// - Parameters:
    ///   - workflowName: The registered name of the workflow type to start.
    ///   - workflowOptions: Configuration options controlling workflow execution behavior.
    ///   - workflowHeaders: Custom headers for the workflow start request.
    ///   - workflowInput: The serialized workflow input payloads.
    ///   - updateID: A unique identifier for the update operation.
    ///   - updateName: The name of the update handler to invoke.
    ///   - updateHeaders: Custom headers for the update request.
    ///   - updateInput: The serialized update input payloads.
    ///   - waitForStage: The stage to wait for before returning from the update request.
    ///   - callOptions: Optional gRPC call options for customizing the request.
    /// - Returns: An ``UpdateWithStartResult`` containing the workflow run ID and update ID.
    /// - Throws: An error if the operation fails.
    func startUpdateWithStartWorkflow(
        workflowName: String,
        workflowOptions: WorkflowOptions,
        workflowHeaders: [String: Api.Common.V1.Payload],
        workflowInput: [Api.Common.V1.Payload],
        updateID: String,
        updateName: String,
        updateHeaders: [String: Api.Common.V1.Payload],
        updateInput: [Api.Common.V1.Payload],
        waitForStage: WorkflowUpdateStage,
        callOptions: CallOptions? = nil
    ) async throws -> UpdateWithStartResult {
        let dataConverter = self.configuration.dataConverter

        // Build the start workflow request
        let startReq = try await Api.Workflowservice.V1.StartWorkflowExecutionRequest(
            namespace: self.configuration.namespace,
            identity: self.configuration.identity,
            requestID: UUID().uuidString,
            workflowTypeName: workflowName,
            workflowOptions: workflowOptions,
            dataConverter: dataConverter,
            headers: workflowHeaders,
            inputs: workflowInput
        )

        // Build the update workflow request
        var updateReq = Api.Workflowservice.V1.UpdateWorkflowExecutionRequest.with {
            $0.namespace = self.configuration.namespace
            $0.workflowExecution.workflowID = workflowOptions.id
            $0.request.meta.identity = self.configuration.identity
            $0.request.meta.updateID = updateID
            $0.request.input.name = updateName
            $0.request.input.args.payloads = updateInput
            $0.waitPolicy.lifecycleStage = .init(waitForStage)
        }

        if !updateHeaders.isEmpty {
            updateReq.request.input.header = try await .init(updateHeaders, with: dataConverter.payloadCodec)
        }

        // Build the multi-operation request
        let multiReq = Api.Workflowservice.V1.ExecuteMultiOperationRequest.with {
            $0.namespace = self.configuration.namespace
            $0.operations = [
                .with { $0.startWorkflow = startReq },
                .with { $0.updateWorkflow = updateReq },
            ]
        }

        // Execute the multi-operation RPC with retry for accepted stage
        var updateResp: Api.Workflowservice.V1.UpdateWorkflowExecutionResponse?
        var runID: String?
        repeat {
            let response: Api.Workflowservice.V1.ExecuteMultiOperationResponse = try await self.client.unary(
                method: Api.Workflowservice.V1.WorkflowService.Method.ExecuteMultiOperation.descriptor,
                request: multiReq,
                callOptions: callOptions
            )

            // Extract run ID from the start workflow response
            if let startResponse = response.responses.first {
                runID = startResponse.startWorkflow.runID
            }

            // Extract update response
            if response.responses.count > 1 {
                updateResp = response.responses[1].updateWorkflow
            }
        } while updateResp == nil
            || updateResp!.stage.rawValue < Api.Enums.V1.UpdateWorkflowExecutionLifecycleStage(waitForStage).rawValue

        return UpdateWithStartResult(
            runID: runID ?? "",
            updateID: updateID
        )
    }
}
