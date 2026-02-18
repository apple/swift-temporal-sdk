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

extension NamespaceUpdatedDescription {
    init(proto: Api.Workflowservice.V1.UpdateNamespaceResponse) {
        self.info = .init(proto: proto.namespaceInfo)
        self.config = .init(proto: proto.config)
        self.replicationConfig = .init(proto: proto.replicationConfig)
        self.isGlobalNamespace = proto.isGlobalNamespace
        self.failoverVersion = Int(proto.failoverVersion)
    }
}
