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

extension NamespaceFailoverStatus {
    init(proto: Temporal_Api_Replication_V1_FailoverStatus) {
        if proto.hasFailoverTime {
            self.failoverTime = proto.failoverTime.date
        }

        self.failoverVersion = Int(proto.failoverVersion)
    }
}
