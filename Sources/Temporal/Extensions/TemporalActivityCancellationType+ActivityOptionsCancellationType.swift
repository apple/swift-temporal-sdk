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

extension Coresdk.WorkflowCommands.ActivityCancellationType {
    init(cancellationType: ActivityOptions.CancellationType) {
        switch cancellationType {
        case .tryCancel:
            self = .tryCancel
        case .waitCancellationCompleted:
            self = .waitCancellationCompleted
        case .abandon:
            self = .abandon
        case .DO_NOT_EXHAUSTIVELY_MATCH_OVER_THIS_ENUM:
            fatalError("Unknown activity cancellation type")
        }
    }
}
