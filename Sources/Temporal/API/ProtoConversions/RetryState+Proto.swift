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

extension RetryState {
    init(retryState: Api.Enums.V1.RetryState) {
        switch retryState {
        case .unspecified:
            self = .unspecified
        case .inProgress:
            self = .inProgress
        case .nonRetryableFailure:
            self = .nonRetryableFailure
        case .timeout:
            self = .timeout
        case .maximumAttemptsReached:
            self = .maximumAttemptsReached
        case .retryPolicyNotSet:
            self = .retryPolicyNotSet
        case .internalServerError:
            self = .internalServerError
        case .cancelRequested:
            self = .cancelRequested
        case .UNRECOGNIZED(let int):
            assertionFailure("Unknwon retry state \(int)")
            self = .unspecified
        }
    }
}

extension Api.Enums.V1.RetryState {
    init(retryState: RetryState) {
        switch retryState {
        case .unspecified:
            self = .unspecified
        case .inProgress:
            self = .inProgress
        case .nonRetryableFailure:
            self = .nonRetryableFailure
        case .timeout:
            self = .timeout
        case .retryPolicyNotSet:
            self = .retryPolicyNotSet
        case .maximumAttemptsReached:
            self = .maximumAttemptsReached
        case .internalServerError:
            self = .internalServerError
        case .cancelRequested:
            self = .cancelRequested
        }
    }
}
