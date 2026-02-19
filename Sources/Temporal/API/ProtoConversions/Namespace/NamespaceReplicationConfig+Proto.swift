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

extension NamespaceReplicationConfig {
    init(proto: Api.Replication.V1.NamespaceReplicationConfig) {
        self.activeClusterName = proto.activeClusterName.isEmpty ? nil : proto.activeClusterName
        self.clusters = proto.clusters.map { $0.clusterName }
        self.state = .init(proto: proto.state)
    }
}

extension Api.Replication.V1.NamespaceReplicationConfig {
    init(replicationConfig: NamespaceReplicationConfig) {
        self = .init()
        self.activeClusterName = replicationConfig.activeClusterName ?? ""
        self.clusters = replicationConfig.clusters.map { cluster in
            .with {
                $0.clusterName = cluster
            }
        }
        if let state = replicationConfig.state {
            self.state = .init(state: state)
        }
    }
}
