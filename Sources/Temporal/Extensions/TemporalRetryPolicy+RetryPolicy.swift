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

extension Temporal_Api_Common_V1_RetryPolicy {
    init(retryPolicy: RetryPolicy) {
        self = .with {
            $0.backoffCoefficient = retryPolicy.backoffCoefficient
            $0.maximumAttempts = Int32(retryPolicy.maximumAttempts)
            $0.nonRetryableErrorTypes = retryPolicy.nonRetryableErrorTypes
        }

        if let initialInterval = retryPolicy.initialInterval {
            self.initialInterval = .init(duration: initialInterval)
        }

        if let maximumInterval = retryPolicy.maximumInterval {
            self.maximumInterval = .init(duration: maximumInterval)
        }
    }
}

extension RetryPolicy {
    package init(retryPolicy: Temporal_Api_Common_V1_RetryPolicy) {
        self = .init(
            backoffCoefficient: retryPolicy.backoffCoefficient,
            maximumAttempts: Int(retryPolicy.maximumAttempts),
            nonRetryableErrorTypes: retryPolicy.nonRetryableErrorTypes
        )
        if retryPolicy.hasInitialInterval {
            self.initialInterval = .init(protobufDuration: retryPolicy.initialInterval)
        }
        if retryPolicy.hasMaximumInterval {
            self.maximumInterval = .init(protobufDuration: retryPolicy.maximumInterval)
        }
    }
}
