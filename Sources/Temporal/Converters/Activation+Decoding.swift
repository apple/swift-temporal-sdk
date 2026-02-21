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

extension Coresdk.WorkflowActivation.WorkflowActivation {
    package mutating func decode(payloadCodec: some PayloadCodec) async throws {
        for index in self.jobs.indices {
            switch self.jobs[index].variant {
            case .initializeWorkflow(var initializeWorkflow):
                try await self.decode(payloads: &initializeWorkflow.arguments, payloadCodec: payloadCodec)
                try await self.decode(payloadDictionary: &initializeWorkflow.headers, payloadCodec: payloadCodec)
                if initializeWorkflow.hasContinuedFailure {
                    try await self.decode(temporalFailure: &initializeWorkflow.continuedFailure, payloadCodec: payloadCodec)
                }
                if initializeWorkflow.hasLastCompletionResult {
                    try await self.decode(payloads: &initializeWorkflow.lastCompletionResult, payloadCodec: payloadCodec)
                }
                if initializeWorkflow.hasMemo {
                    try await self.decode(payloadDictionary: &initializeWorkflow.memo.fields, payloadCodec: payloadCodec)
                }
                if initializeWorkflow.hasSearchAttributes {
                    try await self.decode(payloadDictionary: &initializeWorkflow.searchAttributes.indexedFields, payloadCodec: payloadCodec)
                }
                self.jobs[index].variant = .initializeWorkflow(initializeWorkflow)

            case .queryWorkflow(var queryWorkflow):
                try await self.decode(payloads: &queryWorkflow.arguments, payloadCodec: payloadCodec)
                try await self.decode(payloadDictionary: &queryWorkflow.headers, payloadCodec: payloadCodec)
                self.jobs[index].variant = .queryWorkflow(queryWorkflow)

            case .cancelWorkflow(let cancelWorkflow):
                self.jobs[index].variant = .cancelWorkflow(cancelWorkflow)

            case .signalWorkflow(var signalWorkflow):
                try await self.decode(payloads: &signalWorkflow.input, payloadCodec: payloadCodec)
                try await self.decode(payloadDictionary: &signalWorkflow.headers, payloadCodec: payloadCodec)
                self.jobs[index].variant = .signalWorkflow(signalWorkflow)

            case .resolveActivity(var resolveActivity):
                if resolveActivity.hasResult {
                    switch resolveActivity.result.status {
                    case .completed(var completed):
                        if completed.hasResult {
                            try await self.decode(payload: &completed.result, payloadCodec: payloadCodec)
                        }
                        resolveActivity.result.status = .completed(completed)

                    case .cancelled(var cancelled):
                        if cancelled.hasFailure {
                            try await self.decode(temporalFailure: &cancelled.failure, payloadCodec: payloadCodec)
                        }
                        resolveActivity.result.status = .cancelled(cancelled)

                    case .failed(var failed):
                        if failed.hasFailure {
                            try await self.decode(temporalFailure: &failed.failure, payloadCodec: payloadCodec)
                        }
                        resolveActivity.result.status = .failed(failed)

                    case .backoff:
                        // No nested payloads
                        break

                    case .none:
                        break
                    }
                }

                self.jobs[index].variant = .resolveActivity(resolveActivity)

            case .resolveChildWorkflowExecutionStart(var resolveChildWorkflowExecutionStart):
                switch resolveChildWorkflowExecutionStart.status {
                case .succeeded, .failed:
                    // No nested payloads
                    break

                case .cancelled(var cancelled):
                    if cancelled.hasFailure {
                        try await self.decode(temporalFailure: &cancelled.failure, payloadCodec: payloadCodec)
                    }
                    resolveChildWorkflowExecutionStart.status = .cancelled(cancelled)

                case .none:
                    break
                }

                self.jobs[index].variant = .resolveChildWorkflowExecutionStart(resolveChildWorkflowExecutionStart)

            case .resolveChildWorkflowExecution(var resolveChildWorkflowExecution):
                if resolveChildWorkflowExecution.hasResult {
                    switch resolveChildWorkflowExecution.result.status {
                    case .completed(var completed):
                        if completed.hasResult {
                            try await self.decode(payload: &completed.result, payloadCodec: payloadCodec)
                        }
                        resolveChildWorkflowExecution.result.status = .completed(completed)

                    case .failed(var failed):
                        if failed.hasFailure {
                            try await self.decode(temporalFailure: &failed.failure, payloadCodec: payloadCodec)
                        }
                        resolveChildWorkflowExecution.result.status = .failed(failed)

                    case .cancelled(var cancelled):
                        if cancelled.hasFailure {
                            try await self.decode(temporalFailure: &cancelled.failure, payloadCodec: payloadCodec)
                        }
                        resolveChildWorkflowExecution.result.status = .cancelled(cancelled)

                    case .none:
                        break
                    }
                }

                self.jobs[index].variant = .resolveChildWorkflowExecution(resolveChildWorkflowExecution)

            case .resolveSignalExternalWorkflow(var resolveSignalExternalWorkflow):
                if resolveSignalExternalWorkflow.hasFailure {
                    try await self.decode(temporalFailure: &resolveSignalExternalWorkflow.failure, payloadCodec: payloadCodec)
                }
                self.jobs[index].variant = .resolveSignalExternalWorkflow(resolveSignalExternalWorkflow)

            case .resolveRequestCancelExternalWorkflow(var resolveRequestCancelExternalWorkflow):
                if resolveRequestCancelExternalWorkflow.hasFailure {
                    try await self.decode(temporalFailure: &resolveRequestCancelExternalWorkflow.failure, payloadCodec: payloadCodec)
                }

                self.jobs[index].variant = .resolveRequestCancelExternalWorkflow(resolveRequestCancelExternalWorkflow)

            case .doUpdate(var doUpdate):
                try await self.decode(payloads: &doUpdate.input, payloadCodec: payloadCodec)
                try await self.decode(payloadDictionary: &doUpdate.headers, payloadCodec: payloadCodec)

                self.jobs[index].variant = .doUpdate(doUpdate)

            case .resolveNexusOperationStart(var resolveNexusOperationStart):
                switch resolveNexusOperationStart.status {
                case .operationToken, .startedSync:
                    // No nested payloads
                    break

                case .failed(var failure):
                    try await self.decode(temporalFailure: &failure, payloadCodec: payloadCodec)
                    resolveNexusOperationStart.failed = failure

                case .none:
                    break
                }

                self.jobs[index].variant = .resolveNexusOperationStart(resolveNexusOperationStart)

            case .resolveNexusOperation(var resolveNexusOperation):
                if resolveNexusOperation.hasResult {
                    switch resolveNexusOperation.result.status {
                    case .completed(var completed):
                        try await self.decode(payload: &completed, payloadCodec: payloadCodec)
                        resolveNexusOperation.result.completed = completed

                    case .failed(var failed):
                        try await self.decode(temporalFailure: &failed, payloadCodec: payloadCodec)
                        resolveNexusOperation.result.failed = failed

                    case .cancelled(var cancelled):
                        try await self.decode(temporalFailure: &cancelled, payloadCodec: payloadCodec)
                        resolveNexusOperation.result.cancelled = cancelled

                    case .timedOut(var timedOut):
                        try await self.decode(temporalFailure: &timedOut, payloadCodec: payloadCodec)
                        resolveNexusOperation.result.timedOut = timedOut

                    case .none:
                        break
                    }
                }

                self.jobs[index].variant = .resolveNexusOperation(resolveNexusOperation)

            case .fireTimer, .updateRandomSeed, .notifyHasPatch, .removeFromCache:
                // No nested payloads
                break

            case .none:
                break
            }
        }
    }

    private func decode(payload: inout Api.Common.V1.Payload, payloadCodec: some PayloadCodec) async throws {
        payload = try await payloadCodec.decode(payload: payload)
    }

    private func decode(payloads: inout [Api.Common.V1.Payload], payloadCodec: some PayloadCodec) async throws {
        for index in payloads.indices {
            payloads[index] = try await payloadCodec.decode(payload: payloads[index])
        }
    }

    private func decode(payloads: inout Api.Common.V1.Payloads, payloadCodec: some PayloadCodec) async throws {
        try await self.decode(payloads: &payloads.payloads, payloadCodec: payloadCodec)
    }

    private func decode(payloadDictionary: inout [String: Api.Common.V1.Payload], payloadCodec: some PayloadCodec) async throws {
        for key in payloadDictionary.keys {
            payloadDictionary[key] = try await payloadCodec.decode(payload: payloadDictionary[key]!)
        }
    }

    private func decode(temporalFailure: inout Api.Failure.V1.Failure, payloadCodec: some PayloadCodec) async throws {
        temporalFailure = try await .init(temporalFailure: payloadCodec.decode(temporalFailure: .init(temporalAPIFailure: temporalFailure)))
    }
}
