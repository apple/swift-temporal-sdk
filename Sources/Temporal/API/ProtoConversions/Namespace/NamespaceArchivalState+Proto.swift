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

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

extension NamespaceArchivalState {
    init?(proto: Api.Enums.V1.ArchivalState, url urlString: String?) {
        switch proto {
        case .disabled:
            self = .disabled
        case .enabled:
            guard let urlString, let url = URL(string: urlString) else {
                return nil
            }
            self = .enabled(url)
        default:
            return nil
        }
    }
}
