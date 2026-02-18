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

extension ReplicationState {
    init?(proto: Api.Enums.V1.ReplicationState) {
        switch proto {
        case .normal:
            self = .normal
        case .handover:
            self = .handover
        default:
            return nil
        }
    }
}

extension Api.Enums.V1.ReplicationState {
    init(state: ReplicationState) {
        switch state {
        case .normal:
            self = .normal
        case .handover:
            self = .handover
        }
    }
}
