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

extension Api.Common.V1.Priority {
    package init(_ priority: Priority) {
        self.init()
        self.priorityKey = Int32(priority.priorityKey ?? 0)
        self.fairnessKey = priority.fairnessKey ?? ""
        self.fairnessWeight = priority.fairnessWeight ?? 0
    }
}

extension Priority {
    package init(proto: Api.Common.V1.Priority) {
        self.init(
            priorityKey: proto.priorityKey != 0 ? Int(proto.priorityKey) : nil,
            fairnessKey: proto.fairnessKey.isEmpty ? nil : proto.fairnessKey,
            fairnessWeight: proto.fairnessWeight != 0 ? proto.fairnessWeight : nil
        )
    }
}
