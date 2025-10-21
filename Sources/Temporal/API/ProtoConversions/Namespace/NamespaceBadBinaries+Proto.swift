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

extension NamespaceBadBinaries {
    init(proto: Temporal_Api_Namespace_V1_BadBinaries) {
        self.binaries = proto.binaries.mapValues { .init(proto: $0) }
    }
}

extension NamespaceBadBinaries.Info {
    init(proto: Temporal_Api_Namespace_V1_BadBinaryInfo) {
        self.reason = proto.reason.isEmpty ? nil : proto.reason
        self.operator = proto.operator.isEmpty ? nil : proto.operator
        if proto.hasCreateTime {
            self.createdAt = proto.createTime.date
        }
    }
}

extension Temporal_Api_Namespace_V1_BadBinaries {
    init(badBinaries: NamespaceBadBinaries) {
        self.binaries = badBinaries.binaries.mapValues { .init(info: $0) }
    }
}

extension Temporal_Api_Namespace_V1_BadBinaryInfo {
    init(info: NamespaceBadBinaries.Info) {
        self.reason = info.reason ?? ""
        self.operator = info.operator ?? ""
        if let createdAt = info.createdAt {
            self.createTime = .init(date: createdAt)
        }
    }
}
