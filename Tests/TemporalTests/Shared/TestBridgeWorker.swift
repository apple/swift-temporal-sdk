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

    func pollWorkflowActivation() async throws -> Coresdk_WorkflowActivation_WorkflowActivation {
        try await self.base.pollWorkflowActivation()
    }

    func completeWorkflowActivation(
        completion: Coresdk_WorkflowCompletion_WorkflowActivationCompletion
    ) async throws {
        try await self.base.completeWorkflowActivation(completion: completion)
    }

    func pollActivityTask() async throws -> Coresdk_ActivityTask_ActivityTask {
        try await self.base.pollActivityTask()
    }

    func completeActivityTask(
        _ completion: Coresdk_ActivityTaskCompletion
    ) async throws {
        try await self.base.completeActivityTask(completion)
    }

    func recordActivityHeartbeat(
        _ heartbeat: Coresdk_ActivityHeartbeat
    ) throws {
        try self.base.recordActivityHeartbeat(heartbeat)
    }
}
