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

protocol ActivityWorkerForwarding: ActivityWorkerProtocol where BridgeWorker: BridgeWorkerProtocol {
    var base: ActivityWorker<BridgeWorker> { get }
}

extension ActivityWorkerForwarding {
    func run() async throws {
        try await base.run()
    }
}
