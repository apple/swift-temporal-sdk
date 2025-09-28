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

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

extension NamespaceArchivalState {
    init?(proto: Temporal_Api_Enums_V1_ArchivalState, url urlString: String?) {
        switch proto {
        case .disabled:
            self = .disabled
        case .enabled:
            // TODO: More graceful error handelling
            guard let urlString else {
                fatalError("NamespaceArchivalState(proto:url): When the activation state is enabled, the archival URL must be provided.")
            }

            guard let url = URL(string: urlString) else {
                fatalError("NamespaceArchivalState(proto:url): When the activation state is enabled, the archival URL must be valid.")
            }

            self = .enabled(url)
        default:
            return nil
        }
    }
}
