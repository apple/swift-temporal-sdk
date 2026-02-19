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

protocol WorkflowWorkerForwarding: WorkflowWorkerProtocol where BridgeWorker: BridgeWorkerProtocol {
    var base: WorkflowWorker<BridgeWorker> { get }
}

extension WorkflowWorkerForwarding {
    var worker: BridgeWorker { self.base.worker }
    var interceptors: [any WorkerInterceptor] { self.base.interceptors }

    func run() async throws {
        try await self.base.run()
    }

    func completeWorkflowActivation(
        completion: consuming Coresdk.WorkflowCompletion.WorkflowActivationCompletion
    ) async throws {
        try await self.base.completeWorkflowActivation(completion: completion)
    }
}
