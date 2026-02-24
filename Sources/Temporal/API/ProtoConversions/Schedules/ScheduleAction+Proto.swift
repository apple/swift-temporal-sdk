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

extension Api.Schedule.V1.ScheduleAction {
    init<Input: Sendable>(action: ScheduleAction<Input>, dataConverter: DataConverter) async throws {
        guard case .startWorkflow(let scheduleActionStartWorkflow) = action else {
            fatalError("`ScheduleAction` type not supported.")  // TODO: Improve error
        }

        // TODO: Introduce additional guards and conversions here once all properties on `WorkflowOptions` are supported, see https://github.com/temporalio/sdk-dotnet/blob/bac42d3db19617fae17bc1965e1a9c33fd517fc1/src/Temporalio/Client/Schedules/ScheduleActionStartWorkflow.cs#L124

        self = .init()
        self.startWorkflow.workflowID = scheduleActionStartWorkflow.options.id
        self.startWorkflow.workflowType.name = scheduleActionStartWorkflow.workflowName
        self.startWorkflow.taskQueue.name = scheduleActionStartWorkflow.options.taskQueue
        self.startWorkflow.input.payloads = try await dataConverter.convertValues(scheduleActionStartWorkflow.input)
        if !scheduleActionStartWorkflow.headers.isEmpty {
            self.startWorkflow.header = try await .init(scheduleActionStartWorkflow.headers, with: dataConverter.payloadCodec)
        }
        if let executionTimeOut = scheduleActionStartWorkflow.options.executionTimeOut {
            self.startWorkflow.workflowExecutionTimeout = .init(duration: executionTimeOut)
        }

        if let retryPolicy = scheduleActionStartWorkflow.options.retryPolicy {
            self.startWorkflow.retryPolicy = .init(retryPolicy: retryPolicy)
        }

        if let memo = scheduleActionStartWorkflow.options.memo {
            var temporalPayloads = [String: Api.Common.V1.Payload]()
            for (key, value) in memo {
                temporalPayloads[key] = try await dataConverter.convertValue(value)
            }
            self.startWorkflow.memo = .with {
                $0.fields = temporalPayloads
            }
        }

        if let searchAttributes = scheduleActionStartWorkflow.options.searchAttributes, !searchAttributes.isEmpty {
            self.startWorkflow.searchAttributes = .init(searchAttributes)
        }
    }
}

extension ScheduleAction {
    init(proto: Api.Schedule.V1.ScheduleAction, dataConverter: DataConverter, inputType: Input.Type = Input.self) async throws {
        switch proto.action {
        case .startWorkflow(let proto):
            let input: Input
            if Input.self == Void.self {
                input = () as! Input
            } else {
                input = try await dataConverter.convertPayloads(
                    proto.input.payloads,
                    as: Input.self
                )
            }

            let headers: [String: Api.Common.V1.Payload]
            if proto.hasHeader && !proto.header.fields.isEmpty {
                headers = try await proto.header.decoded(with: dataConverter.payloadCodec)
            } else {
                headers = [:]
            }

            self = .startWorkflow(
                .init(
                    workflowName: proto.workflowType.name,
                    options: .init(
                        id: proto.workflowID,
                        taskQueue: proto.taskQueue.name,
                        retryPolicy: .init(retryPolicy: proto.retryPolicy),
                        executionTimeOut: .init(proto.workflowExecutionTimeout)
                    ),
                    headers: headers,
                    input: input
                )
            )
        case .none:
            fatalError("ScheduleAction(proto:dataConverter:workflowType) unexpected `nil` action.")
        }
    }
}
