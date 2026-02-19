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

extension NamespaceDescription {
    init(proto: Api.Workflowservice.V1.DescribeNamespaceResponse) {
        self.info = .init(proto: proto.namespaceInfo)
        self.config = .init(proto: proto.config)
        self.replicationConfig = .init(proto: proto.replicationConfig)

        self.failoverVersion = Int(proto.failoverVersion)
        self.isGlobalNamespace = proto.isGlobalNamespace

        self.failoverHistory = proto.failoverHistory.map { .init(proto: $0) }
    }
}
