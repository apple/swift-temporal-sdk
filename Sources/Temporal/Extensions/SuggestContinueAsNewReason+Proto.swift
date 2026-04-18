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

extension SuggestContinueAsNewReason {
    init(_ proto: Api.Enums.V1.SuggestContinueAsNewReason) {
        switch proto {
        case .unspecified:
            self = .unspecified
        case .historySizeTooLarge:
            self = .historySizeTooLarge
        case .tooManyHistoryEvents:
            self = .tooManyHistoryEvents
        case .tooManyUpdates:
            self = .tooManyUpdates
        case .UNRECOGNIZED:
            self = .unspecified
        }
    }
}
