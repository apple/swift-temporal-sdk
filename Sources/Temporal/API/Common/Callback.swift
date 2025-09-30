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

import struct Foundation.Data

/// Callback to attach to various events in the system (workflow run completion).
public struct Callback: Hashable, Sendable {
    public var variant: Variant

    public init(variant: Variant) {
        self.variant = variant
    }
}

extension Callback {
    public enum Variant: Hashable, Sendable {
        case nexus(Nexus)
        case `internal`(Internal)
    }

    public struct Nexus: Hashable, Sendable {
        public var url: String
        public var headers: [String: String]

        public init(url: String, headers: [String: String]) {
            self.url = url
            self.headers = headers
        }
    }

    public struct Internal: Hashable, Sendable {
        public var data: Data

        public init(data: Data) {
            self.data = data
        }
    }
}
