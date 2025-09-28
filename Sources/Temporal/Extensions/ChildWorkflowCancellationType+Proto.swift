//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Temporal SDK open source project
//
// Copyright (c) 2025 Apple Inc. and the Swift Temporal SDK project authors
// Licensed under MIT License
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Swift Cassandra Client project authors
//
// SPDX-License-Identifier: MIT
//
//===----------------------------------------------------------------------===//

extension Coresdk_ChildWorkflow_ChildWorkflowCancellationType {
    init(childWorkflowCancellationType: ChildWorkflowCancellationType) {
        switch childWorkflowCancellationType {
        case .abandon:
            self = .abandon
        case .tryCancel:
            self = .tryCancel
        case .waitCancellationCompleted:
            self = .waitCancellationCompleted
        case .waitCancellationRequested:
            self = .waitCancellationRequested
        }
    }
}
