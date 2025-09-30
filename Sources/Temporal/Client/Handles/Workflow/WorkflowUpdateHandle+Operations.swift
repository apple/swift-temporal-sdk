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

import struct GRPCCore.CallOptions

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

extension WorkflowUpdateHandle {
    /// Retrieves the result of the workflow update operation.
    ///
    /// This method waits for the workflow update to complete and returns its result. The update
    /// must have been successfully processed by the workflow before this method can return a value.
    /// The method suspends until the update reaches a terminal state (completed or failed).
    ///
    /// - Parameters:
    ///    - callOptions: Optional gRPC call options for customizing the behavior of the underlying request.
    /// - Returns: The typed result of the update operation.
    /// - Throws: An error if the update fails, is rejected, or cannot be completed.
    public func result(
        callOptions: CallOptions? = nil
    ) async throws -> WorkflowUpdate.Output {
        try await self.untypedHandle.result(
            resultTypes: WorkflowUpdate.Output.self,
            callOptions: callOptions
        )
    }
}
