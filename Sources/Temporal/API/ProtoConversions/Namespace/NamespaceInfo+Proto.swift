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

extension NamespaceInfo {
    init(proto: Api.Namespace.V1.NamespaceInfo) {
        self.name = proto.name
        self.id = proto.id
        self.state = .init(proto: proto.state)
        self.description = proto.description_p.isEmpty ? nil : proto.description_p
        self.ownerEmail = proto.ownerEmail.isEmpty ? nil : proto.ownerEmail
        self.data = proto.data
        self.capabilities = .init(proto: proto.capabilities)
        self.supportsSchedules = proto.supportsSchedules
    }
}

extension NamespaceInfo.State {
    init?(proto: Api.Enums.V1.NamespaceState) {
        switch proto {
        case .registered:
            self = .registered
        case .deprecated:
            self = .deprecated
        case .deleted:
            self = .deleted
        default:
            return nil
        }
    }
}

extension NamespaceInfo.Capabilities {
    init(proto: Api.Namespace.V1.NamespaceInfo.Capabilities) {
        self.eagerWorkflowStart = proto.eagerWorkflowStart
        self.syncUpdate = proto.syncUpdate
        self.asyncUpdate = proto.asyncUpdate
    }
}

extension Api.Enums.V1.NamespaceState {
    init(state: NamespaceInfo.State) {
        switch state {
        case .registered:
            self = .registered
        case .deprecated:
            self = .deprecated
        case .deleted:
            self = .deleted
        }
    }
}
