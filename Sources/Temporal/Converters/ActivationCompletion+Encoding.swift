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

extension Coresdk.WorkflowCompletion.WorkflowActivationCompletion {
    package mutating func encode(payloadCodec: some PayloadCodec) async throws {
        switch self.status {
        case .successful(let successful):
            for index in successful.commands.indices {
                switch successful.commands[index].variant {
                case .startTimer, .requestCancelActivity, .cancelTimer, .cancelWorkflowExecution, .setPatchMarker, .cancelChildWorkflowExecution,
                    .requestCancelExternalWorkflowExecution, .cancelSignalWorkflow, .requestCancelLocalActivity, .requestCancelNexusOperation:
                    // No payload protos
                    break

                case .scheduleActivity(var scheduleActivity):
                    try await self.encode(payloads: &scheduleActivity.arguments, payloadCodec: payloadCodec)
                    try await self.encode(payloadDictionary: &scheduleActivity.headers, payloadCodec: payloadCodec)

                    self.successful.commands[index].variant = .scheduleActivity(scheduleActivity)

                case .respondToQuery(var respondToQuery):
                    switch respondToQuery.variant {
                    case .succeeded(var succeeded):
                        if succeeded.hasResponse {
                            try await self.encode(payload: &succeeded.response, payloadCodec: payloadCodec)
                        }
                        respondToQuery.succeeded = succeeded

                    case .failed(var failed):
                        try await self.encode(temporalFailure: &failed, payloadCodec: payloadCodec)
                        respondToQuery.failed = failed

                    case .none:
                        break
                    }
                    self.successful.commands[index].variant = .respondToQuery(respondToQuery)

                case .completeWorkflowExecution(var completeWorkflowExecution):
                    if completeWorkflowExecution.hasResult {
                        try await self.encode(payload: &completeWorkflowExecution.result, payloadCodec: payloadCodec)
                    }
                    self.successful.commands[index].variant = .completeWorkflowExecution(completeWorkflowExecution)

                case .failWorkflowExecution(var failWorkflowExecution):
                    if failWorkflowExecution.hasFailure {
                        try await self.encode(temporalFailure: &failWorkflowExecution.failure, payloadCodec: payloadCodec)
                    }
                    self.successful.commands[index].variant = .failWorkflowExecution(failWorkflowExecution)

                case .continueAsNewWorkflowExecution(var continueAsNewWorkflowExecution):
                    try await self.encode(payloads: &continueAsNewWorkflowExecution.arguments, payloadCodec: payloadCodec)
                    try await self.encode(payloadDictionary: &continueAsNewWorkflowExecution.memo, payloadCodec: payloadCodec)
                    try await self.encode(payloadDictionary: &continueAsNewWorkflowExecution.headers, payloadCodec: payloadCodec)
                    try await self.encode(payloadDictionary: &continueAsNewWorkflowExecution.searchAttributes, payloadCodec: payloadCodec)

                    self.successful.commands[index].variant = .continueAsNewWorkflowExecution(continueAsNewWorkflowExecution)

                case .startChildWorkflowExecution(var startChildWorkflowExecution):
                    try await self.encode(payloads: &startChildWorkflowExecution.input, payloadCodec: payloadCodec)
                    try await self.encode(payloadDictionary: &startChildWorkflowExecution.memo, payloadCodec: payloadCodec)
                    try await self.encode(payloadDictionary: &startChildWorkflowExecution.headers, payloadCodec: payloadCodec)
                    try await self.encode(payloadDictionary: &startChildWorkflowExecution.searchAttributes, payloadCodec: payloadCodec)

                    self.successful.commands[index].variant = .startChildWorkflowExecution(startChildWorkflowExecution)

                case .signalExternalWorkflowExecution(var signalExternalWorkflowExecution):
                    try await self.encode(payloads: &signalExternalWorkflowExecution.args, payloadCodec: payloadCodec)
                    try await self.encode(payloadDictionary: &signalExternalWorkflowExecution.headers, payloadCodec: payloadCodec)

                    self.successful.commands[index].variant = .signalExternalWorkflowExecution(signalExternalWorkflowExecution)

                case .scheduleLocalActivity(var scheduleLocalActivity):
                    try await self.encode(payloads: &scheduleLocalActivity.arguments, payloadCodec: payloadCodec)
                    try await self.encode(payloadDictionary: &scheduleLocalActivity.headers, payloadCodec: payloadCodec)

                    self.successful.commands[index].variant = .scheduleLocalActivity(scheduleLocalActivity)

                case .upsertWorkflowSearchAttributes(var upsertWorkflowSearchAttributes):
                    try await self.encode(payloadDictionary: &upsertWorkflowSearchAttributes.searchAttributes, payloadCodec: payloadCodec)

                    self.successful.commands[index].variant = .upsertWorkflowSearchAttributes(upsertWorkflowSearchAttributes)

                case .modifyWorkflowProperties(var modifyWorkflowProperties):
                    if modifyWorkflowProperties.hasUpsertedMemo {
                        try await self.encode(payloadDictionary: &modifyWorkflowProperties.upsertedMemo.fields, payloadCodec: payloadCodec)
                    }

                    self.successful.commands[index].variant = .modifyWorkflowProperties(modifyWorkflowProperties)

                case .updateResponse(var updateResponse):
                    switch updateResponse.response {
                    case .accepted:
                        break

                    case .completed(var completed):
                        try await self.encode(payload: &completed, payloadCodec: payloadCodec)
                        updateResponse.completed = completed

                    case .rejected(var rejected):
                        try await self.encode(temporalFailure: &rejected, payloadCodec: payloadCodec)
                        updateResponse.rejected = rejected

                    case .none:
                        break
                    }

                    self.successful.commands[index].variant = .updateResponse(updateResponse)

                case .scheduleNexusOperation(var scheduleNexusOperation):
                    if scheduleNexusOperation.hasInput {
                        try await self.encode(payload: &scheduleNexusOperation.input, payloadCodec: payloadCodec)
                    }

                    self.successful.commands[index].variant = .scheduleNexusOperation(scheduleNexusOperation)

                case .none:
                    break
                }
            }
        case .failed(var failed):
            if failed.hasFailure {
                try await self.encode(temporalFailure: &failed.failure, payloadCodec: payloadCodec)
            }
            self.failed = failed

        case .none:
            break
        }
    }

    private func encode(payload: inout Api.Common.V1.Payload, payloadCodec: some PayloadCodec) async throws {
        payload = .init(temporalPayload: try await payloadCodec.encode(payload: .init(temporalAPIPayload: payload)))
    }

    private func encode(payloads: inout [Api.Common.V1.Payload], payloadCodec: some PayloadCodec) async throws {
        for index in payloads.indices {
            payloads[index] = .init(temporalPayload: try await payloadCodec.encode(payload: .init(temporalAPIPayload: payloads[index])))
        }
    }

    private func encode(payloads: inout Api.Common.V1.Payloads, payloadCodec: some PayloadCodec) async throws {
        try await self.encode(payloads: &payloads.payloads, payloadCodec: payloadCodec)
    }

    private func encode(payloadDictionary: inout [String: Api.Common.V1.Payload], payloadCodec: some PayloadCodec) async throws {
        for key in payloadDictionary.keys {
            payloadDictionary[key] = .init(
                temporalPayload: try await payloadCodec.encode(payload: .init(temporalAPIPayload: payloadDictionary[key]!))
            )
        }
    }

    private func encode(temporalFailure: inout Api.Failure.V1.Failure, payloadCodec: some PayloadCodec) async throws {
        temporalFailure = try await .init(temporalFailure: payloadCodec.encode(temporalFailure: .init(temporalAPIFailure: temporalFailure)))
    }
}
