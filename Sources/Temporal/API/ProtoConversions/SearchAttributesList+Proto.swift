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

extension SearchAttributeKeyCollection {
    init(proto: Temporal_Api_Operatorservice_V1_ListSearchAttributesResponse) {
        self.customAttributes = proto.customAttributes.mapValues { .init($0) }
        self.systemAttributes = proto.systemAttributes.mapValues { .init($0) }
        self.storageSchema = proto.storageSchema
    }
}
