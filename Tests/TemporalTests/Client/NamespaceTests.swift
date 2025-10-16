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

import AsyncAlgorithms
import Foundation
import GRPCCore
import GRPCNIOTransportHTTP2Posix
import Temporal
import TemporalTestKit
import Testing

extension TestServerDependentTests {
    @Suite(.tags(.clientTests))
    struct NamespaceTests {
        @Test
        func registerAndFetchNamespace() async throws {
            try await withTestClient { client in
                let namespaceName = "namespace-test-\(UUID().uuidString)"
                let workflowExecutionRetentionPeriod: Duration = .seconds(3 * 24 * 60 * 60)  // 3 days retention
                let description = "namespace description"
                let ownerEmail = "owner@foo.com"
                let data = ["foo": "bar"]
                let securityToken = "token123"
                let isGlobalNamespace = false
                let historyArchivalState: NamespaceArchivalState = try .enabled(#require(.init(string: "file:///Users/test/Desktop/")))
                let visibilityArchivalState: NamespaceArchivalState = .disabled

                try await client.namespaceService.registerNamespace(
                    name: namespaceName,
                    workflowExecutionRetentionPeriod: workflowExecutionRetentionPeriod,
                    description: description,
                    ownerEmail: ownerEmail,
                    data: data,
                    securityToken: securityToken,
                    isGlobalNamespace: isGlobalNamespace,
                    historyArchivalState: historyArchivalState,
                    visibilityArchivalState: visibilityArchivalState
                )

                // Fetch namespace via name
                let namespace = try await client.namespaceService.describeNamespace(namespace: .name(namespaceName))
                #expect(namespace.info.name == namespaceName)
                #expect(namespace.info.id.isEmpty == false)
                #expect(namespace.info.description == description)
                #expect(namespace.info.ownerEmail == ownerEmail)
                #expect(namespace.info.data == data)
                #expect(namespace.info.state == .registered)
                #expect(namespace.info.supportsSchedules == true)
                #expect(namespace.info.capabilities.asyncUpdate == true)
                #expect(namespace.info.capabilities.syncUpdate == true)
                #expect(namespace.info.capabilities.eagerWorkflowStart == true)
                #expect(namespace.config.workflowExecutionRetentionTtl == workflowExecutionRetentionPeriod)
                withKnownIssue(
                    "Temporal doesn't seem to acknowledge the `enabled` history archival state (inc. the URL), even though it is correctly set on the request"
                ) {
                    #expect(namespace.config.historyArchivalState == historyArchivalState)
                }
                #expect(namespace.config.visibilityArchivalState == visibilityArchivalState)
                #expect(namespace.config.customSearchAttributeAliases?.isEmpty == true)
                #expect(namespace.config.badBinaries?.binaries.isEmpty == true)
                #expect(namespace.isGlobalNamespace == isGlobalNamespace)
                #expect(namespace.failoverHistory == [])
                #expect(namespace.failoverVersion == 0)
                #expect(namespace.replicationConfig.activeClusterName == "active")
                #expect(namespace.replicationConfig.clusters.count == 1)
                #expect(namespace.replicationConfig.clusters.first == "active")
                #expect(namespace.replicationConfig.state == .normal)

                // Fetch namespace via ID
                let namespaceViaId = try await client.namespaceService.describeNamespace(namespace: .id(namespace.info.id))

                #expect(namespace == namespaceViaId)

                try await client.namespaceService.deleteNamespace(namespace: .name(namespaceName), delay: .zero)
            }
        }

        @Test
        func deleteNamespace() async throws {
            try await withTestClient { client in
                let namespaceName = "namespace-test-\(UUID().uuidString)"
                try await client.namespaceService.registerNamespace(
                    name: namespaceName,
                    workflowExecutionRetentionPeriod: .seconds(3 * 24 * 60 * 60)  // 3 days retention
                )

                _ = try await client.namespaceService.describeNamespace(namespace: .name(namespaceName))

                let tempDeleteNamespaceName = try await client.namespaceService.deleteNamespace(namespace: .name(namespaceName), delay: .zero)
                #expect(tempDeleteNamespaceName.starts(with: namespaceName))
            }
        }

        @Test
        func listNamespaces() async throws {
            try await withTestClient { client in
                let namespaceName = "namespace-test-\(UUID().uuidString)"
                try await client.namespaceService.registerNamespace(
                    name: namespaceName,
                    workflowExecutionRetentionPeriod: .seconds(3 * 24 * 60 * 60),
                    description: "test123"
                )

                let namespaces: [NamespaceDescription] = try await Array(client.namespaceService.listNamespaces())
                #expect(namespaces.count >= 3)  // 2 existing namespaces by default from Temporal
                let foundNamespace = try #require(namespaces.first { $0.info.name == namespaceName })

                let namespace = try await client.namespaceService.describeNamespace(namespace: .name(namespaceName))
                #expect(foundNamespace == namespace)

                // Test two namespaces
                let namespaceNameSecond = "namespace-test-\(UUID().uuidString)"
                try await client.namespaceService.registerNamespace(
                    name: namespaceNameSecond,
                    workflowExecutionRetentionPeriod: .seconds(5 * 24 * 60 * 60),
                    ownerEmail: "owner@foo.com"
                )

                let namespacesSecond: [NamespaceDescription] = try await Array(client.namespaceService.listNamespaces())
                #expect(namespacesSecond.count >= 4)  // 2 existing namespaces by default from Temporal

                let foundNamespaceFirst = try #require(namespacesSecond.first { $0.info.name == namespaceName })
                let foundNamespaceSecond = try #require(namespacesSecond.first { $0.info.name == namespaceNameSecond })
                try #require(await client.namespaceService.describeNamespace(namespace: .name(namespaceName)) == foundNamespaceFirst)
                try #require(await client.namespaceService.describeNamespace(namespace: .name(namespaceNameSecond)) == foundNamespaceSecond)

                // Test a deleted namespace
                try await client.namespaceService.deleteNamespace(namespace: .name(namespaceName), delay: .zero)

                // without listing deleted namespaces
                let namespacesThird: [NamespaceDescription] = try await Array(client.namespaceService.listNamespaces())
                #expect(namespacesThird.count >= 3)  // 2 existing namespaces by default from Temporal
                #expect(namespacesThird.allSatisfy { $0.info.name != namespaceName })
                #expect(namespacesThird.contains(where: { $0.info.name == namespaceNameSecond }))

                // with listing deleted namespaces
                let namespacesForth: [NamespaceDescription] = try await Array(client.namespaceService.listNamespaces(includeDeleted: true))
                #expect(namespacesForth.count >= 4)  // 2 existing namespaces by default from Temporal
                // only prefix matches as deleted namespaces are appended with a "deleted-<ID>" suffix
                #expect(namespacesForth.contains(where: { $0.info.name.starts(with: namespaceName) }))
                #expect(namespacesForth.contains(where: { $0.info.name == namespaceNameSecond }))

                try await client.namespaceService.deleteNamespace(namespace: .name(namespaceNameSecond), delay: .zero)
            }
        }

        @Test
        func updateNamespace() async throws {
            try await withTestClient { client in
                let namespaceName = "namespace-test-\(UUID().uuidString)"
                try await client.namespaceService.registerNamespace(
                    name: namespaceName,
                    workflowExecutionRetentionPeriod: .seconds(3 * 24 * 60 * 60),
                    description: "test123",
                    ownerEmail: "owner@foo.com",
                    data: [:]
                )

                let newUpdateInfo = NamespaceUpdateInfo(
                    description: "new namespace description",
                    ownerEmail: "owner2@foo.com",
                    data: ["new": "data"],
                    state: .deprecated  // set namespace to deprecated
                )

                let newConfig = NamespaceConfig(
                    workflowExecutionRetentionTtl: .seconds(10 * 24 * 60 * 60)
                )

                let updatedNamespace = try await client.namespaceService.updateNamespace(
                    namespace: namespaceName,
                    updateInfo: newUpdateInfo,
                    config: newConfig
                )

                #expect(updatedNamespace.info.description == newUpdateInfo.description)
                #expect(updatedNamespace.info.ownerEmail == newUpdateInfo.ownerEmail)
                #expect(updatedNamespace.info.data == newUpdateInfo.data)
                #expect(updatedNamespace.info.state == newUpdateInfo.state)
                #expect(updatedNamespace.config.workflowExecutionRetentionTtl == newConfig.workflowExecutionRetentionTtl)

                // Verify update via fetch
                let fetchedNamespace = try await client.namespaceService.describeNamespace(namespace: .name(namespaceName))
                #expect(fetchedNamespace.info.description == newUpdateInfo.description)
                #expect(fetchedNamespace.info.ownerEmail == newUpdateInfo.ownerEmail)
                #expect(fetchedNamespace.info.data == newUpdateInfo.data)
                #expect(fetchedNamespace.info.state == newUpdateInfo.state)
                #expect(fetchedNamespace.config.workflowExecutionRetentionTtl == newConfig.workflowExecutionRetentionTtl)

                try await client.namespaceService.deleteNamespace(namespace: .name(namespaceName), delay: .zero)
            }
        }

        @Test
        func deprecateNamespace() async throws {
            try await withTestClient { client in
                let namespaceName = "namespace-test-\(UUID().uuidString)"
                try await client.namespaceService.registerNamespace(
                    name: namespaceName,
                    workflowExecutionRetentionPeriod: .seconds(3 * 24 * 60 * 60)
                )

                try await client.namespaceService.deprecateNamespace(namespace: namespaceName)
                try #expect(await client.namespaceService.describeNamespace(namespace: .name(namespaceName)).info.state == .deprecated)

                try await client.namespaceService.deleteNamespace(namespace: .name(namespaceName), delay: .zero)
            }
        }
    }
}
