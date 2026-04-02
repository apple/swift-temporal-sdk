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

extension Api.Update.V1.Outcome {
    /// Extracts the success payloads from this update outcome, or throws on failure.
    ///
    /// - Parameter dataConverter: The data converter to use for failure conversion.
    /// - Returns: The raw success payloads.
    /// - Throws: ``WorkflowUpdateFailedError`` if the outcome is a failure or has no value.
    package func successPayloads(
        using dataConverter: DataConverter
    ) async throws -> [Api.Common.V1.Payload] {
        switch self.value {
        case .success(let success):
            return success.payloads
        case .failure(let failure):
            let error = await dataConverter.convertFailure(failure)
            throw WorkflowUpdateFailedError(cause: error)
        case .none:
            throw WorkflowUpdateFailedError(
                cause: BasicTemporalFailureError(message: "Update outcome has no value", stackTrace: "")
            )
        }
    }
}
