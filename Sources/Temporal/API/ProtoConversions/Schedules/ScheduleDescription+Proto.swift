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

extension ScheduleDescription {
    init(proto: Api.Workflowservice.V1.DescribeScheduleResponse, dataConverter: DataConverter) async throws {
        self.info = .init(proto: proto.info)
        self.schedule = try await .init(proto: proto.schedule, dataConverter: dataConverter)
        self.conflictToken = proto.conflictToken
        self.memo = proto.memo.fields.mapValues { .init(.init(temporalAPIPayload: $0)) }
        self.searchAttributes = try .init(proto.searchAttributes)
    }
}
