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

import struct GRPCCore.CallOptions

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

extension TemporalClient.WorkflowService {
    /// Creates a new workflow schedule with the specified configuration and timing rules.
    ///
    /// Workflow schedules enable automatic execution of workflows based on time-based
    /// triggers such as cron expressions, calendar specifications, or interval patterns.
    /// Once created, the schedule will automatically start workflows according to its
    /// configured timing rules until paused, updated, or deleted.
    ///
    /// - Parameters:
    ///   - id: A unique identifier for the schedule within the namespace.
    ///   - schedule: The ``Schedule`` configuration defining timing, actions, and policies.
    ///   - options: Optional ``ScheduleOptions`` for metadata, initial state, and search attributes.
    /// - Returns: A conflict token used for optimistic concurrency control in subsequent updates.
    /// - Throws: An error if the operation fails.
    @discardableResult
    public func createSchedule<Input: Sendable>(
        id: String,
        schedule: Schedule<Input>,
        options: ScheduleOptions?
    ) async throws -> Data {
        let response: Temporal_Api_Workflowservice_V1_CreateScheduleResponse = try await self.client.unary(
            method: Temporal_Api_Workflowservice_V1_WorkflowService.Method.CreateSchedule.descriptor,
            request: Temporal_Api_Workflowservice_V1_CreateScheduleRequest(
                namespace: self.configuration.namespace,
                identity: self.configuration.identity,
                requestID: UUID().uuidString,
                scheduleID: id,
                schedule: schedule,
                scheduleOptions: options,
                dataConverter: self.configuration.dataConverter
            ),
            callOptions: options?.callOptions
        )

        return response.conflictToken
    }

    /// Retrieves information about an existing workflow schedule.
    ///
    /// This method provides detailed information about a schedule's configuration,
    /// current state, execution history, and runtime metadata. The description includes
    /// all aspects of the schedule including timing specifications, policies, recent
    /// actions, and execution statistics.
    ///
    /// - Parameters:
    ///   - id: The unique identifier of the schedule to describe.
    ///   - inputType: The input type of the workflow associated with the schedule.
    ///   - callOptions: Optional gRPC call options for customizing the behavior of the underlying request.
    /// - Returns: A ``ScheduleDescription`` containing comprehensive schedule information and execution history.
    /// - Throws: An error if the operation fails.
    public func describeSchedule<Input: Sendable>(
        id: String,
        inputType: Input.Type = Input.self,
        callOptions: CallOptions? = nil
    ) async throws -> ScheduleDescription<Input> {
        let response: Temporal_Api_Workflowservice_V1_DescribeScheduleResponse = try await self.client.unary(
            method: Temporal_Api_Workflowservice_V1_WorkflowService.Method.DescribeSchedule.descriptor,
            request: Temporal_Api_Workflowservice_V1_DescribeScheduleRequest.with {
                $0.namespace = self.configuration.namespace
                $0.scheduleID = id
            },
            callOptions: callOptions
        )

        return try await .init(proto: response, dataConverter: self.configuration.dataConverter)
    }

    /// Executes scheduled workflows for historical time periods as if they occurred in real-time.
    ///
    /// Schedule backfill allows you to retroactively execute workflows for time periods
    /// that occurred before the schedule was created or while it was paused. This is
    /// particularly useful for data processing, batch jobs, or any workflow that needs
    /// to process historical data gaps.
    ///
    /// - Parameters:
    ///   - id: The unique identifier of the schedule to backfill.
    ///   - backfills: A sequence of ``ScheduleBackfill`` periods specifying the time ranges and policies for historical execution.
    ///   - callOptions: Optional gRPC call options for customizing the behavior of the underlying request.
    /// - Throws: ``ArgumentError`` if no backfill periods are specified, or an error if the backfill operation fails.
    public func backfillSchedule(
        id: String,
        backfills: some Sequence<ScheduleBackfill>,
        callOptions: CallOptions? = nil
    ) async throws {
        let backfillProto: [Temporal_Api_Schedule_V1_BackfillRequest] = backfills.map { .init(scheduleBackfill: $0) }

        guard !backfillProto.isEmpty else {
            throw ArgumentError(message: "At least one backfill period must be specified.")
        }

        try await self.client.unary(
            method: Temporal_Api_Workflowservice_V1_WorkflowService.Method.PatchSchedule.descriptor,
            request: Temporal_Api_Workflowservice_V1_PatchScheduleRequest.with {
                $0.namespace = self.configuration.namespace
                $0.identity = self.configuration.identity
                $0.requestID = UUID().uuidString
                $0.scheduleID = id
                $0.patch = .with {
                    $0.backfillRequest = backfillProto
                }
            },
            callOptions: callOptions
        )
    }

    /// Triggers an immediate execution of the schedule's action outside of its normal timing.
    ///
    /// Schedule triggering allows you to manually execute a schedule's configured action
    /// immediately, bypassing the normal timing constraints. This is useful for testing,
    /// debugging, or handling urgent processing needs without waiting for the next
    /// scheduled execution time.
    ///
    /// - Parameters:
    ///   - id: The unique identifier of the schedule to trigger.
    ///   - overlap: Optional override for the schedule's overlap policy. If nil, uses the schedule's configured overlap policy.
    ///   - callOptions: Optional gRPC call options for customizing the behavior of the underlying request.
    /// - Throws: An error if the operation fails.
    public func triggerSchedule(
        id: String,
        overlap: ScheduleOverlapPolicy? = nil,
        callOptions: CallOptions? = nil
    ) async throws {
        try await self.client.unary(
            method: Temporal_Api_Workflowservice_V1_WorkflowService.Method.PatchSchedule.descriptor,
            request: Temporal_Api_Workflowservice_V1_PatchScheduleRequest.with {
                $0.namespace = self.configuration.namespace
                $0.identity = self.configuration.identity
                $0.requestID = UUID().uuidString
                $0.scheduleID = id
                $0.patch = .with {
                    $0.triggerImmediately = .with {
                        if let overlap {
                            $0.overlapPolicy = .init(overlapPolicy: overlap)  // `unspecified` is the default policy
                        }
                    }
                }
            },
            callOptions: callOptions
        )
    }

    /// Updates an existing schedule's configuration using an atomic update operation.
    ///
    /// This method provides safe, atomic updates to schedule configurations by using
    /// an update closure that receives the current schedule state and returns the
    /// desired changes. The update process includes conflict detection and automatic
    /// retry logic to handle concurrent modifications.
    ///
    /// - Parameters:
    ///   - id: The unique identifier of the schedule to update.
    ///   - inputType: The input type of the workflow associated with the schedule update.
    ///   - update: A closure that receives the current ``ScheduleDescription`` and returns an optional ``ScheduleUpdate`` with the desired changes.
    ///   - callOptions: Optional gRPC call options for customizing the behavior of the underlying request.
    /// - Throws: An error if the operation fails.
    public func updateSchedule<Input: Sendable>(
        id: String,
        inputType: Input.Type = Input.self,
        _ update: (ScheduleDescription<Input>) async throws -> ScheduleUpdate<Input>?,
        callOptions: CallOptions? = nil
    ) async throws {
        let description = try await self.describeSchedule(id: id, inputType: Input.self)
        guard let scheduleUpdate = try await update(description) else {
            // If no update is indicated (via a `nil` return from the closure), simply return.
            return
        }

        let scheduleUpdateProto = try await Temporal_Api_Schedule_V1_Schedule(
            schedule: scheduleUpdate.schedule,
            dataConverter: self.configuration.dataConverter
        )

        try await self.client.unary(
            method: Temporal_Api_Workflowservice_V1_WorkflowService.Method.UpdateSchedule.descriptor,
            request: Temporal_Api_Workflowservice_V1_UpdateScheduleRequest.with {
                $0.namespace = self.configuration.namespace
                $0.identity = self.configuration.identity
                $0.requestID = UUID().uuidString
                $0.scheduleID = id
                $0.schedule = scheduleUpdateProto
                // Detects modification that possibly occurred between `describeSchedule` and `updateSchedule`, leading to failure and retry.
                // TODO: As of now, the `UpdateSchedule` RPC doesn't throw an error when the token mismatches, however, the update is silently not applied and discarded.. This is expected behavior as Temporal doesn't properly throw on a token mismatch yet
                // Set the `conflictToken` once the Temporal behavior is adjusted.
                //$0.conflictToken = description.conflictToken

                // TODO: SearchAttributes
            },
            callOptions: callOptions
        )
    }

    /// Pauses an active schedule to temporarily stop workflow executions.
    ///
    /// When a schedule is paused, it stops creating new workflow executions according
    /// to its timing configuration. The schedule retains all its configuration and
    /// can be resumed at any time. Pausing is useful for maintenance, testing, or
    /// temporarily halting automated processes.
    ///
    /// - Parameters:
    ///   - id: The unique identifier of the schedule to pause.
    ///   - note: An optional note explaining the reason for pausing. If nil, uses a default message.
    ///   - callOptions: Optional gRPC call options for customizing the behavior of the underlying request.
    /// - Throws: An error if the operation fails.
    public func pauseSchedule(
        id: String,
        note: String? = nil,
        callOptions: CallOptions? = nil
    ) async throws {
        try await self.client.unary(
            method: Temporal_Api_Workflowservice_V1_WorkflowService.Method.PatchSchedule.descriptor,
            request: Temporal_Api_Workflowservice_V1_PatchScheduleRequest.with {
                $0.namespace = self.configuration.namespace
                $0.identity = self.configuration.identity
                $0.requestID = UUID().uuidString
                $0.scheduleID = id
                $0.patch = .with {
                    $0.pause = note ?? "Paused via swift-temporal-sdk"
                }
            },
            callOptions: callOptions
        )
    }

    /// Resumes a paused schedule to restart automatic workflow executions.
    ///
    /// When a schedule is unpaused, it immediately resumes creating workflow executions
    /// according to its configured timing rules. The schedule picks up from where it
    /// left off, respecting its timing configuration without requiring reconfiguration.
    ///
    /// - Parameters:
    ///   - id: The unique identifier of the schedule to resume.
    ///   - note: An optional note explaining the reason for resuming. If nil, uses a default message.
    ///   - callOptions: Optional gRPC call options for customizing the behavior of the underlying request.
    /// - Throws: An error if the operation fails.
    public func unpauseSchedule(
        id: String,
        note: String? = nil,
        callOptions: CallOptions? = nil
    ) async throws {
        try await self.client.unary(
            method: Temporal_Api_Workflowservice_V1_WorkflowService.Method.PatchSchedule.descriptor,
            request: Temporal_Api_Workflowservice_V1_PatchScheduleRequest.with {
                $0.namespace = self.configuration.namespace
                $0.requestID = UUID().uuidString
                $0.identity = self.configuration.identity
                $0.scheduleID = id
                $0.patch = .with {
                    $0.unpause = note ?? "Unpaused via swift-temporal-sdk"
                }
            },
            callOptions: callOptions
        )
    }

    /// Permanently deletes a schedule and stops all future workflow executions.
    ///
    /// Schedule deletion is a permanent operation that removes the schedule configuration
    /// and stops all future workflow executions. This action cannot be undone, and the
    /// schedule will need to be recreated if automation is needed again.
    ///
    /// - Parameters:
    ///    - id: The unique identifier of the schedule to permanently delete.
    ///    - callOptions: Optional gRPC call options for customizing the behavior of the underlying request.
    /// - Throws: An error if the operation fails.
    public func deleteSchedule(id: String, callOptions: CallOptions? = nil) async throws {
        try await self.client.unary(
            method: Temporal_Api_Workflowservice_V1_WorkflowService.Method.DeleteSchedule.descriptor,
            request: Temporal_Api_Workflowservice_V1_DeleteScheduleRequest.with {
                $0.namespace = self.configuration.namespace
                $0.identity = self.configuration.identity
                $0.scheduleID = id
            },
            callOptions: callOptions
        )
    }

    /// Retrieves a paginated list of schedules with optional filtering and search capabilities.
    ///
    /// This method provides efficient access to schedule listings within a namespace,
    /// supporting both comprehensive listing and targeted searches using Temporal's
    /// visibility query language. The results are automatically paginated to handle
    /// large numbers of schedules without memory exhaustion.
    ///
    /// - Parameters:
    ///    - query: A visibility query string for filtering schedules.
    ///             Uses Temporal's query syntax to filter by schedule properties, workflow types, or custom search attributes.
    ///             Empty string returns all schedules.
    ///    - callOptions: Optional gRPC call options for customizing the behavior of the underlying request.
    /// - Returns: An async sequence of ``ScheduleListDescription`` objects representing the
    /// filtered schedules with automatic pagination.
    /// - Throws: An error if the operation fails.
    public func listSchedules(
        query: String = "",
        callOptions: CallOptions? = nil
    ) async throws -> some AsyncSequence<ScheduleListDescription, any Error> & Sendable {
        withFlattenedPagination { pageToken in
            let response: Temporal_Api_Workflowservice_V1_ListSchedulesResponse = try await self.client.unary(
                method: Temporal_Api_Workflowservice_V1_WorkflowService.Method.ListSchedules.descriptor,
                request: Temporal_Api_Workflowservice_V1_ListSchedulesRequest.with {
                    $0.namespace = self.configuration.namespace
                    $0.query = query
                    $0.maximumPageSize = 100
                    $0.nextPageToken = pageToken
                },
                callOptions: callOptions
            )

            return (elements: response.schedules, pageToken: response.nextPageToken)
        }.map { scheduleProto in
            ScheduleListDescription(proto: scheduleProto)
        }
    }
}
