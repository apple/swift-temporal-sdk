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

extension Callback {
    init(_ rawValue: Api.Common.V1.Callback) {
        let variant: Variant =
            switch rawValue.variant {
            case .nexus(let value):
                .nexus(.init(url: value.url, headers: value.header))
            case .internal(let value):
                .internal(.init(data: value.data))
            case nil:
                fatalError("Received unexpected nil variant for Callback")
            }

        self = .init(variant: variant)
    }
}
