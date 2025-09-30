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

extension Temporal_Api_Schedule_V1_Schedule {
    init<Input: Sendable>(schedule: Schedule<Input>, dataConverter: DataConverter) async throws {
        self.action = try await .init(action: schedule.action, dataConverter: dataConverter)
        self.spec = .init(specification: schedule.specification)
        self.policies = .init(policy: schedule.policy)
        self.state = .init(state: schedule.state)
    }
}

extension Schedule {
    init(proto: Temporal_Api_Schedule_V1_Schedule, dataConverter: DataConverter) async throws {
        self.action = try await .init(proto: proto.action, dataConverter: dataConverter, inputType: Input.self)
        self.specification = .init(proto: proto.spec)
        self.policy = .init(proto: proto.policies)
        self.state = .init(proto: proto.state)
    }
}
