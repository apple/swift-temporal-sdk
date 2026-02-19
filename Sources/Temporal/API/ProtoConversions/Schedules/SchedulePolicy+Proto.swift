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

extension Api.Schedule.V1.SchedulePolicies {
    init(policy: SchedulePolicy) {
        self = .init()
        self.overlapPolicy = .init(overlapPolicy: policy.overlap)
        self.catchupWindow = .init(rounding: policy.catchupWindow)
        self.pauseOnFailure = policy.pauseOnFailure
    }
}

extension SchedulePolicy {
    init(proto: Api.Schedule.V1.SchedulePolicies) {
        guard let overlap = ScheduleOverlapPolicy(proto: proto.overlapPolicy) else {
            fatalError("SchedulePolicy(proto:) failed to convert overlapPolicy.")
        }
        self.overlap = overlap
        self.catchupWindow = .init(proto.catchupWindow)
        self.pauseOnFailure = proto.pauseOnFailure
    }
}

extension Api.Enums.V1.ScheduleOverlapPolicy {
    init(overlapPolicy: ScheduleOverlapPolicy) {
        switch overlapPolicy {
        case .skip:
            self = .skip
        case .bufferOne:
            self = .bufferOne
        case .bufferAll:
            self = .bufferAll
        case .cancelOther:
            self = .cancelOther
        case .terminateOther:
            self = .terminateOther
        case .allowAll:
            self = .allowAll
        }
    }
}

extension ScheduleOverlapPolicy {
    init?(proto: Api.Enums.V1.ScheduleOverlapPolicy) {
        switch proto {
        case .skip: self = .skip
        case .bufferOne: self = .bufferOne
        case .bufferAll: self = .bufferAll
        case .cancelOther: self = .cancelOther
        case .terminateOther: self = .terminateOther
        case .allowAll: self = .allowAll
        default: return nil
        }
    }
}
