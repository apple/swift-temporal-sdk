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

extension ScheduleListDescription {
    init(proto: Api.Schedule.V1.ScheduleListEntry) throws {
        self.id = proto.scheduleID
        self.info = .init(proto: proto.info)
        self.schedule = try .init(proto: proto.info)
        if proto.hasMemo && !proto.memo.fields.isEmpty {
            self.memo = proto.memo.fields.mapValues { $0 as any Sendable }
        }
        if proto.hasSearchAttributes && !proto.searchAttributes.indexedFields.isEmpty {
            self.searchAttributes = try? SearchAttributeCollection(proto.searchAttributes)
        }
    }
}
