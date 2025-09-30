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

import struct GRPCCore.CallOptions

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

extension TemporalClient.WorkflowService {
    /// Executes a workflow update by name and waits for its completion with automatic result retrieval.
    ///
    /// This method combines workflow update initiation and result retrieval into a single
    /// operation, providing a convenient way to send updates to running workflows and
    /// wait for their completion. The method uses long polling to wait for the update
    /// to complete, automatically handling the asynchronous nature of workflow updates.
    ///
    /// - Parameters:
    ///   - workflowID: The unique identifier of the target workflow.
    ///   - runID: The specific run ID to update. If nil, targets the latest run.
    ///   - firstExecutionRunID: The run ID of the first execution in the chain for validation. If nil, no chain validation is performed.
    ///   - updateID: A unique identifier for this update operation. Defaults to a new UUID.
    ///   - updateName: The name of the update handler defined in the workflow.
    ///   - headers: Custom headers for tracing, authentication, or update context.
    ///   - input: The input parameters to pass to the update handler.
    ///   - resultTypes: The expected return types from the update operation.
    ///   - callOptions: Optional gRPC call options for customizing the behavior of the underlying request.
    /// - Returns: A tuple containing the update results in the order specified by `resultTypes`.
    /// - Throws: ``WorkflowUpdateFailedError`` if the update execution fails, or an error for other update failures.
    public func executeWorkflowUpdate<each Input: Sendable, each Result: Sendable>(
        workflowID: String,
        runID: String? = nil,
        firstExecutionRunID: String? = nil,
        updateID: String = UUID().uuidString,
        updateName: String,
        headers: [String: TemporalPayload] = [:],
        input: repeat each Input,
        resultTypes: repeat (each Result).Type,
        callOptions: CallOptions? = nil
    ) async throws -> (repeat each Result) {
        _ = try await self.startWorkflowUpdate(
            workflowID: workflowID,
            runID: runID,
            firstExecutionRunID: firstExecutionRunID,
            updateID: updateID,
            updateName: updateName,
            headers: headers,
            input: repeat each input,
            callOptions: callOptions
        )

        return try await self.workflowUpdateResult(
            workflowID: workflowID,
            runID: runID,
            updateID: updateID,
            resultTypes: repeat each resultTypes,
            callOptions: callOptions
        )
    }

    /// Executes a strongly-typed workflow update and waits for its completion with automatic result retrieval.
    ///
    /// This convenience method provides type-safe workflow updating using a
    /// ``WorkflowUpdateDefinition`` that encapsulates the update name, input type,
    /// and output type. This approach ensures compile-time type safety and reduces
    /// the possibility of runtime type conversion errors.
    ///
    /// - Parameters:
    ///   - workflowID: The unique identifier of the target workflow.
    ///   - runID: The specific run ID to update. If nil, targets the latest run.
    ///   - firstExecutionRunID: The run ID of the first execution in the chain for validation. If nil, no chain validation is performed.
    ///   - updateType: The ``WorkflowUpdateDefinition`` type that defines the update contract.
    ///   - updateID: A unique identifier for this update operation. Defaults to a new UUID.
    ///   - headers: Custom headers for tracing, authentication, or update context.
    ///   - input: The input parameter matching the update definition's `Input` type.
    ///   - callOptions: Optional gRPC call options for customizing the behavior of the underlying request.
    /// - Returns: The update result matching the update definition's `Output` type.
    /// - Throws: ``WorkflowUpdateFailedError`` if the update execution fails, or an error for other update failures.
    public func executeWorkflowUpdate<Update: WorkflowUpdateDefinition>(
        workflowID: String,
        runID: String? = nil,
        firstExecutionRunID: String? = nil,
        updateType: Update.Type = Update.self,
        updateID: String = UUID().uuidString,
        headers: [String: TemporalPayload] = [:],
        input: Update.Input,
        callOptions: CallOptions? = nil
    ) async throws -> Update.Output {
        try await self.executeWorkflowUpdate(
            workflowID: workflowID,
            runID: runID,
            firstExecutionRunID: firstExecutionRunID,
            updateID: updateID,
            updateName: Update.name,
            headers: headers,
            input: input,
            resultTypes: Update.Output.self,
            callOptions: callOptions
        )
    }

    // MARK: - Start Workflow Update

    /// Initiates a workflow update by name without waiting for completion.
    ///
    /// This method sends an update request to a running workflow and returns immediately
    /// after the update is accepted, without waiting for the update to complete. Use this
    /// method when you want to start an update asynchronously and retrieve results later
    /// using ``workflowUpdateResult(workflowID:runID:updateID:resultTypes:callOptions:)``.
    ///
    /// - Parameters:
    ///   - workflowID: The unique identifier of the target workflow.
    ///   - runID: The specific run ID to update. If nil, targets the latest run.
    ///   - firstExecutionRunID: The run ID of the first execution in the chain for validation. If nil, no chain validation is performed.
    ///   - updateID: A unique identifier for this update operation. Defaults to a new UUID.
    ///   - updateName: The name of the update handler defined in the workflow.
    ///   - headers: Custom headers for tracing, authentication, or update context.
    ///   - input: The input parameters to pass to the update handler.
    ///   - callOptions: Optional gRPC call options for customizing the behavior of the underlying request.
    /// - Returns: The unique update ID that can be used to retrieve results later.
    /// - Throws: An error if the update cannot be started or accepted by the workflow.
    public func startWorkflowUpdate<each Input: Sendable>(
        workflowID: String,
        runID: String? = nil,
        firstExecutionRunID: String? = nil,
        updateID: String = UUID().uuidString,
        updateName: String,
        headers: [String: TemporalPayload] = [:],
        input: repeat each Input,
        callOptions: CallOptions? = nil
    ) async throws -> String {
        // TODO: Precondition for WaitForStage options
        let dataConverter = configuration.dataConverter
        let inputPayloads = try await dataConverter.convertValues(repeat each input)

        var request = Temporal_Api_Workflowservice_V1_UpdateWorkflowExecutionRequest.with {
            $0.namespace = self.configuration.namespace
            $0.workflowExecution.workflowID = workflowID
            if let runID {
                $0.workflowExecution.runID = runID
            }
            if let firstExecutionRunID {
                $0.firstExecutionRunID = firstExecutionRunID
            }
            $0.request.meta.identity = self.configuration.identity
            $0.request.meta.updateID = updateID
            $0.request.input.name = updateName
            $0.request.input.args.payloads = inputPayloads.map { .init(temporalPayload: $0) }
            // TODO: Add support for wait policy
            //            $0.waitPolicy
        }

        if !headers.isEmpty {
            request.request.input.header = try await .init(headers, with: dataConverter.payloadCodec)
        }

        var response: Temporal_Api_Workflowservice_V1_UpdateWorkflowExecutionResponse
        repeat {
            do {
                response = try await self.client.unary(
                    method: Temporal_Api_Workflowservice_V1_WorkflowService.Method.UpdateWorkflowExecution.descriptor,
                    request: request,
                    callOptions: callOptions
                )
            } catch {
                throw error
            }
        } while response.stage.rawValue < Temporal_Api_Enums_V1_UpdateWorkflowExecutionLifecycleStage.accepted.rawValue

        return updateID
    }

    /// Initiates a strongly-typed workflow update without waiting for completion.
    ///
    /// This convenience method provides type-safe workflow updating using a
    /// ``WorkflowUpdateDefinition`` that encapsulates the update name and input type.
    /// The method returns immediately after the update is accepted, allowing you to
    /// retrieve results later using the returned update ID.
    ///
    /// - Parameters:
    ///   - workflowID: The unique identifier of the target workflow.
    ///   - runID: The specific run ID to update. If nil, targets the latest run.
    ///   - firstExecutionRunID: The run ID of the first execution in the chain for validation. If nil, no chain validation is performed.
    ///   - updateType: The ``WorkflowUpdateDefinition`` type that defines the update contract.
    ///   - updateID: A unique identifier for this update operation. Defaults to a new UUID.
    ///   - headers: Custom headers for tracing, authentication, or update context.
    ///   - input: The input parameter matching the update definition's `Input` type.
    ///   - callOptions: Optional gRPC call options for customizing the behavior of the underlying request.
    /// - Returns: The unique update ID that can be used to retrieve results later.
    /// - Throws: An error if the update cannot be started or accepted by the workflow.
    public func startWorkflowUpdate<Update: WorkflowUpdateDefinition>(
        workflowID: String,
        runID: String? = nil,
        firstExecutionRunID: String? = nil,
        updateType: Update.Type = Update.self,
        updateID: String = UUID().uuidString,
        headers: [String: TemporalPayload] = [:],
        input: Update.Input,
        callOptions: CallOptions? = nil
    ) async throws -> String {
        try await self.startWorkflowUpdate(
            workflowID: workflowID,
            runID: runID,
            firstExecutionRunID: firstExecutionRunID,
            updateID: updateID,
            updateName: Update.name,
            headers: headers,
            input: input,
            callOptions: callOptions
        )
    }

    // MARK: - Workflow Update Result

    /// Retrieves the result of a previously started workflow update using long polling.
    ///
    /// This method waits for a workflow update to complete and returns its results.
    /// It uses long polling to efficiently wait until the update finishes processing,
    /// automatically handling retries and connection timeouts. Use this method after
    /// starting an update with ``startWorkflowUpdate(workflowID:runID:firstExecutionRunID:updateID:updateName:headers:input:callOptions:)``.
    ///
    /// - Parameters:
    ///   - workflowID: The unique identifier of the target workflow.
    ///   - runID: The specific run ID that was updated. If nil, uses the latest run.
    ///   - updateID: The unique identifier of the update to retrieve results for.
    ///   - resultTypes: The expected return types from the update operation.
    ///   - callOptions: Optional gRPC call options for customizing the behavior of the underlying request.
    /// - Returns: A tuple containing the update results in the order specified by `resultTypes`.
    /// - Throws: ``WorkflowUpdateFailedError`` if the update execution failed, or an error for other retrieval failures including timeouts.
    public func workflowUpdateResult<each Result: Sendable>(
        workflowID: String,
        runID: String? = nil,
        updateID: String,
        resultTypes: repeat (each Result).Type,
        callOptions: CallOptions? = nil
    ) async throws -> (repeat each Result) {
        // This setups a long poll since we need to wait until the
        // update completed. We don't have to sleep between each request
        // since the request will wait until the various timeouts trigger.
        while true {
            do {
                let response: Temporal_Api_Workflowservice_V1_PollWorkflowExecutionUpdateResponse = try await self.client.unary(
                    method: Temporal_Api_Workflowservice_V1_WorkflowService.Method.PollWorkflowExecutionUpdate.descriptor,
                    request: Temporal_Api_Workflowservice_V1_PollWorkflowExecutionUpdateRequest.with {
                        $0.namespace = self.configuration.namespace
                        $0.updateRef.workflowExecution.workflowID = workflowID
                        if let runID {
                            $0.updateRef.workflowExecution.runID = runID
                        }
                        $0.updateRef.updateID = updateID
                        $0.identity = self.configuration.identity
                        $0.waitPolicy.lifecycleStage = .completed
                    },
                    callOptions: callOptions ?? .userPollRetryOptions
                )

                if response.hasOutcome {
                    switch response.outcome.value {
                    case .success(let success):
                        return try await self.configuration.dataConverter.convertPayloads(
                            success.payloads.map { .init(temporalAPIPayload: $0) },
                            as: repeat each resultTypes
                        )
                    case .failure(let failure):
                        let error = await self.configuration.dataConverter.convertTemporalFailure(.init(temporalAPIFailure: failure))
                        throw WorkflowUpdateFailedError(cause: error)
                    case .none:
                        break
                    }
                }
            } catch {
                // TODO: We need to convert out deadline exceeds and cancels here
                throw error
            }
        }
    }

    /// Retrieves the result of a previously started strongly-typed workflow update using long polling.
    ///
    /// This convenience method provides type-safe result retrieval for workflow updates
    /// using a ``WorkflowUpdateDefinition`` that encapsulates the output type. The method
    /// waits for the update to complete and returns results with compile-time type safety.
    ///
    /// - Parameters:
    ///   - workflowID: The unique identifier of the target workflow.
    ///   - runID: The specific run ID that was updated. If nil, uses the latest run.
    ///   - updateType: The ``WorkflowUpdateDefinition`` type that defines the update contract.
    ///   - updateID: The unique identifier of the update to retrieve results for. Defaults to a new UUID.
    ///   - callOptions: Optional gRPC call options for customizing the behavior of the underlying request.
    /// - Returns: The update result matching the update definition's `Output` type.
    /// - Throws: ``WorkflowUpdateFailedError`` if the update execution failed, or an error for
    /// other retrieval failures including timeouts.
    public func workflowUpdateResult<Update: WorkflowUpdateDefinition>(
        workflowID: String,
        runID: String? = nil,
        updateType: Update.Type = Update.self,
        updateID: String = UUID().uuidString,
        callOptions: CallOptions? = nil
    ) async throws -> Update.Output {
        try await self.workflowUpdateResult(
            workflowID: workflowID,
            runID: runID,
            updateID: updateID,
            resultTypes: Update.Output.self,
            callOptions: callOptions
        )
    }
}
