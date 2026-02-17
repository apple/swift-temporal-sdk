//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Temporal SDK open source project
//
// Copyright (c) 2026 Apple Inc. and the Swift Temporal SDK project authors
// Licensed under MIT License
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Swift Temporal SDK project authors
//
// SPDX-License-Identifier: MIT
//
//===----------------------------------------------------------------------===//

final class NamespacesGenerator {
    let typeRegistry: TypeRegistry
    let namespaceTree: NamespaceTree

    init(typeRegistry: TypeRegistry) {
        self.typeRegistry = typeRegistry
        self.namespaceTree = NamespaceTree()
    }

    func buildTree() {
        for typeInfo in typeRegistry.allTypes() {
            namespaceTree.insert(path: typeInfo.namespace, accessLevel: typeInfo.accessLevel)
        }
    }

    func generateNamespacesFile() -> String {
        return namespaceTree.generateSwiftCode()
    }
}
