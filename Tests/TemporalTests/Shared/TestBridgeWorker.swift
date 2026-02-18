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
import Logging
import Temporal

protocol BridgeWorkerForwarding: BridgeWorkerProtocol {
    var base: BridgeWorker { get }
}

extension BridgeWorkerForwarding {
    func initiateShutdown() {
        self.base.initiateShutdown()
    }

    func finalizeShutdown() async throws {
        try await self.base.finalizeShutdown()
    }

    func pollWorkflowActivation() async throws -> Coresdk.WorkflowActivation.WorkflowActivation {
        try await self.base.pollWorkflowActivation()
    }

    func completeWorkflowActivation(
        completion: Coresdk.WorkflowCompletion.WorkflowActivationCompletion
    ) async throws {
        try await self.base.completeWorkflowActivation(completion: completion)
    }

    func pollActivityTask() async throws -> Coresdk.ActivityTask.ActivityTask {
        try await self.base.pollActivityTask()
    }

    func completeActivityTask(
        _ completion: Coresdk.ActivityTaskCompletion
    ) async throws {
        try await self.base.completeActivityTask(completion)
    }

    func recordActivityHeartbeat(
        _ heartbeat: Coresdk.ActivityHeartbeat
    ) throws {
        try self.base.recordActivityHeartbeat(heartbeat)
    }
}
