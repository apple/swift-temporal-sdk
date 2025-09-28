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

import Temporal

func ensureSearchAttributesPresent<each Value>(
    namespace: String? = nil,
    attributes typedAttributes: repeat SearchAttributeKey<each Value>
) async throws {
    var attributes = [AnySearchAttributeKey]()
    for attribute in repeat each typedAttributes {
        attributes.append(.init(attribute))
    }
    guard !attributes.isEmpty else { return }

    try await withTestClient(namespace: namespace ?? "default") { client in
        try await ensureSearchAttributesPresent(client: client, namespace: namespace, attributes: attributes)
    }
}

func ensureSearchAttributesPresent(client: TemporalClient, namespace: String? = nil, attributes: [AnySearchAttributeKey]) async throws {
    let operatorService = client.operatorService
    let response = try await operatorService.listSearchAttributes(namespace: namespace)
    let existingCustomAttributes = response.customAttributes
    let existingSystemAttributes = response.systemAttributes

    let attributesToCreate = attributes.filter {
        !existingCustomAttributes.keys.contains($0.name) && !existingSystemAttributes.keys.contains($0.name)
    }
    guard !attributesToCreate.isEmpty else {
        return
    }

    try await operatorService.addSearchAttributes(namespace: namespace, attributesToCreate)

    let postResponse = try await operatorService.listSearchAttributes(namespace: namespace)
    let customAttributes = postResponse.customAttributes
    let systemAttributes = postResponse.systemAttributes
    for attribute in attributes {
        guard !customAttributes.keys.contains(attribute.name) && !systemAttributes.keys.contains(attribute.name) else {
            continue
        }
        fatalError("Added search attribute but was not returned \(attribute.name)")
    }
}
