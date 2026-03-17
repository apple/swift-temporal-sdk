//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Temporal SDK open source project
//
// Copyright (c) 2026 Apple Inc. and the Swift Temporal SDK project authors
// Licensed under MIT License
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Swift Temporal SDK project authors
//
// SPDX-License-Identifier: MIT
//
//===----------------------------------------------------------------------===//

import Temporal
import Testing

@Suite
struct IsCanceledTests {
    @Test
    func canceledError() {
        let error = CanceledError(message: "canceled")
        #expect(error.isTemporalCancellation)
    }

    @Test
    func swiftCancellationError() {
        let error = CancellationError()
        #expect(error.isTemporalCancellation)
    }

    @Test
    func activityErrorWrappingCanceledError() {
        let error = ActivityError(
            message: "Activity failed",
            cause: CanceledError(message: "canceled"),
            stackTrace: "",
            scheduledEventID: 1,
            startedEventID: 2,
            activityID: "activity-1",
            activityType: "MyActivity",
            identity: "worker-1",
            retryState: .inProgress
        )
        #expect(error.isTemporalCancellation)
    }

    @Test
    func activityErrorWithoutCanceledCause() {
        let error = ActivityError(
            message: "Activity failed",
            cause: ApplicationError(message: "some error"),
            stackTrace: "",
            scheduledEventID: 1,
            startedEventID: 2,
            activityID: "activity-1",
            activityType: "MyActivity",
            identity: "worker-1",
            retryState: .inProgress
        )
        #expect(!error.isTemporalCancellation)
    }

    @Test
    func childWorkflowErrorWrappingCanceledError() {
        let error = ChildWorkflowError(
            message: "Child workflow failed",
            cause: CanceledError(message: "canceled"),
            stackTrace: "",
            namespace: "default",
            workflowID: "wf-1",
            runID: "run-1",
            workflowName: "MyWorkflow",
            retryState: .inProgress
        )
        #expect(error.isTemporalCancellation)
    }

    @Test
    func childWorkflowErrorWithoutCanceledCause() {
        let error = ChildWorkflowError(
            message: "Child workflow failed",
            cause: ApplicationError(message: "some error"),
            stackTrace: "",
            namespace: "default",
            workflowID: "wf-1",
            runID: "run-1",
            workflowName: "MyWorkflow",
            retryState: .inProgress
        )
        #expect(!error.isTemporalCancellation)
    }

    @Test
    func applicationErrorIsNotCanceled() {
        let error = ApplicationError(message: "some error")
        #expect(!error.isTemporalCancellation)
    }

    @Test
    func workflowUpdateRPCTimeoutOrCanceledErrorIsNotCanceled() {
        let error = WorkflowUpdateRPCTimeoutOrCanceledError()
        #expect(!error.isTemporalCancellation)
    }
}
