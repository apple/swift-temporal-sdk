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

import Foundation
import SwiftProtobuf

extension NamespaceConfig {
    init(proto: Api.Namespace.V1.NamespaceConfig) {
        if proto.hasWorkflowExecutionRetentionTtl {
            self.workflowExecutionRetentionTtl = .init(proto.workflowExecutionRetentionTtl)
        }

        if proto.hasBadBinaries {
            self.badBinaries = .init(proto: proto.badBinaries)
        }

        self.historyArchivalState = .init(proto: proto.historyArchivalState, url: proto.historyArchivalUri)
        self.visibilityArchivalState = .init(proto: proto.visibilityArchivalState, url: proto.visibilityArchivalUri)

        self.customSearchAttributeAliases = proto.customSearchAttributeAliases
    }
}

extension Api.Namespace.V1.NamespaceConfig {
    init(config: NamespaceConfig) {
        self = .init()
        if let workflowExecutionRetentionTtl = config.workflowExecutionRetentionTtl {
            self.workflowExecutionRetentionTtl = .init(duration: workflowExecutionRetentionTtl)
        }

        if let badBinaries = config.badBinaries {
            self.badBinaries = .init(badBinaries: badBinaries)
        }

        switch config.historyArchivalState {
        case .enabled(let url):
            self.historyArchivalState = .enabled
            self.historyArchivalUri = url.absoluteString
        case .disabled:
            self.historyArchivalState = .disabled
        case .none:
            break
        }

        switch config.visibilityArchivalState {
        case .enabled(let url):
            self.visibilityArchivalState = .enabled
            self.visibilityArchivalUri = url.absoluteString
        case .disabled:
            self.visibilityArchivalState = .disabled
        case .none:
            break
        }

        if let customSearchAttributeAliases = config.customSearchAttributeAliases {
            self.customSearchAttributeAliases = customSearchAttributeAliases
        }
    }
}
