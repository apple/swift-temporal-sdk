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

extension Temporal_Api_Namespace_V1_UpdateNamespaceInfo {
    init(updateInfo: NamespaceUpdateInfo) {
        if let description = updateInfo.description {
            self.description_p = description
        }
        if let ownerEmail = updateInfo.ownerEmail {
            self.ownerEmail = ownerEmail
        }
        if let data = updateInfo.data {
            self.data = data
        }
        if let state = updateInfo.state {
            self.state = .init(state: state)
        }
    }
}
