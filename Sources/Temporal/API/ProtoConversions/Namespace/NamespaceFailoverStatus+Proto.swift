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

extension NamespaceFailoverStatus {
    init(proto: Api.Replication.V1.FailoverStatus) {
        if proto.hasFailoverTime {
            self.failoverTime = proto.failoverTime.date
        }

        self.failoverVersion = Int(proto.failoverVersion)
    }
}
