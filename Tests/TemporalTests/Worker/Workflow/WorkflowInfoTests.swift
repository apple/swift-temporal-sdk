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

import Foundation
import SwiftProtobuf
import Temporal
import TemporalTestKit
import Testing

extension TestServerDependentTests {
    @Suite(.tags(.workflowTests))
    struct WorkflowInfoTests {
        @Workflow
        final class InfoWorkflow {
            func run(input: Void) async throws -> WorkflowInfo {
                Workflow.info
            }
        }

        @Test
        func workflowInfo() async throws {
            let id = "wf-\(UUID().uuidString)"
            let taskQueue = "tq-\(UUID().uuidString)"

            let info = try await executeWorkflow(
                InfoWorkflow.self,
                input: (),
                taskQueue: taskQueue,
                id: id
            )

            #expect(info.attempt == 1)

            #expect(info.startTime > .now.advanced(by: -30))
            #expect(info.startTime < .now)

            #expect(info.workflowName == "InfoWorkflow")
            #expect(info.workflowID == id)
            #expect(info.workflowType == "InfoWorkflow")

            #expect(info.continuedRunID == nil)

            #expect(info.taskQueue == taskQueue)
            #expect(info.namespace == "default")
            #expect(info.cronSchedule == nil)

            #expect(info.runTimeout == nil)
            #expect(info.taskTimeout == .seconds(10))
            #expect(info.executionTimeout == nil)

            #expect(info.lastFailure == nil)
            #expect(info.lastResult == nil)
            #expect(info.parent == nil)
            #expect(info.retryPolicy == nil)
        }
    }
}

// MARK: Codable

extension RetryPolicy: Codable {
    enum CodingKeys: String, CodingKey {
        case initialInterval, backoffCoefficient, maximumInterval, maximumAttempts
    }
    func encode(to encoder: any Swift.Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(initialInterval, forKey: .initialInterval)
        try container.encode(backoffCoefficient, forKey: .backoffCoefficient)
        try container.encodeIfPresent(maximumInterval, forKey: .maximumInterval)
        try container.encode(maximumAttempts, forKey: .maximumAttempts)
    }
    init(from decoder: any Swift.Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self = try .init(
            initialInterval: container.decodeIfPresent(Duration.self, forKey: .initialInterval),
            backoffCoefficient: container.decode(Double.self, forKey: .backoffCoefficient),
            maximumInterval: container.decodeIfPresent(Duration.self, forKey: .maximumInterval),
            maximumAttempts: container.decode(Int.self, forKey: .maximumAttempts)
        )
    }
}

extension TemporalRawValue: Codable {
    func encode(to encoder: any Swift.Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(payload)
    }
    init(from decoder: any Swift.Decoder) throws {
        let container = try decoder.singleValueContainer()
        self = .init(try container.decode(Api.Common.V1.Payload.self))
    }
}

extension Api.Common.V1.Payload: Codable {
    enum CodingKeys: String, CodingKey {
        case data, metadata
    }
    func encode(to encoder: any Swift.Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(data, forKey: .data)
        try container.encode(metadata, forKey: .metadata)
    }
    init(from decoder: any Swift.Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self = try .with {
            $0.data = try container.decode(Data.self, forKey: .data)
            $0.metadata = try container.decode([String: Data].self, forKey: .metadata)
        }
    }
}

extension WorkflowInfo.Parent: Codable {
    enum CodingKeys: String, CodingKey {
        case workflowID, runID, namespace
    }
    func encode(to encoder: any Swift.Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(workflowID, forKey: .workflowID)
        try container.encode(runID, forKey: .runID)
        try container.encode(namespace, forKey: .namespace)
    }
    init(from decoder: any Swift.Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self = try .init(
            workflowID: container.decode(String.self, forKey: .workflowID),
            runID: container.decode(String.self, forKey: .runID),
            namespace: container.decode(String.self, forKey: .namespace)
        )
    }
}

extension WorkflowInfo: Codable {
    enum CodingKeys: String, CodingKey {
        case attempt, startTime, workflowName, workflowID, workflowType
        case runID, continuedRunID, taskQueue, namespace, cronSchedule, headers
        case runTimeout, taskTimeout, executionTimeout
        case lastFailure, lastResult, parent, retryPolicy
    }
    func encode(to encoder: any Swift.Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(attempt, forKey: .attempt)
        try container.encode(startTime, forKey: .startTime)
        try container.encode(workflowName, forKey: .workflowName)
        try container.encode(workflowID, forKey: .workflowID)
        try container.encode(workflowType, forKey: .workflowType)
        try container.encode(runID, forKey: .runID)
        try container.encodeIfPresent(continuedRunID, forKey: .continuedRunID)
        try container.encode(taskQueue, forKey: .taskQueue)
        try container.encode(namespace, forKey: .namespace)
        try container.encodeIfPresent(cronSchedule, forKey: .cronSchedule)
        try container.encodeIfPresent(runTimeout, forKey: .runTimeout)
        try container.encodeIfPresent(taskTimeout, forKey: .taskTimeout)
        try container.encodeIfPresent(executionTimeout, forKey: .executionTimeout)
        try container.encodeIfPresent(lastResult, forKey: .lastResult)
        try container.encodeIfPresent(parent, forKey: .parent)
        try container.encodeIfPresent(retryPolicy, forKey: .retryPolicy)
        try container.encodeIfPresent(headers, forKey: .headers)
        // NOTE: This currently doesn't encode lastFailure.
    }

    init(from decoder: any Swift.Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self = try .init(
            attempt: container.decode(Int.self, forKey: .attempt),
            startTime: container.decode(Date.self, forKey: .startTime),
            workflowName: container.decode(String.self, forKey: .workflowName),
            workflowID: container.decode(String.self, forKey: .workflowID),
            workflowType: container.decode(String.self, forKey: .workflowType),
            runID: container.decode(String.self, forKey: .runID),
            taskQueue: container.decode(String.self, forKey: .taskQueue),
            namespace: container.decode(String.self, forKey: .namespace),
            headers: container.decode([String: Api.Common.V1.Payload].self, forKey: .headers)
        )
        self.continuedRunID = try container.decodeIfPresent(String.self, forKey: .continuedRunID)
        self.cronSchedule = try container.decodeIfPresent(String.self, forKey: .cronSchedule)
        self.runTimeout = try container.decodeIfPresent(Duration.self, forKey: .runTimeout)
        self.taskTimeout = try container.decodeIfPresent(Duration.self, forKey: .taskTimeout)
        self.executionTimeout = try container.decodeIfPresent(Duration.self, forKey: .executionTimeout)
        self.lastResult = try container.decodeIfPresent([TemporalRawValue].self, forKey: .lastResult)
        self.parent = try container.decodeIfPresent(Parent.self, forKey: .parent)
        self.retryPolicy = try container.decodeIfPresent(RetryPolicy.self, forKey: .retryPolicy)
    }
}
