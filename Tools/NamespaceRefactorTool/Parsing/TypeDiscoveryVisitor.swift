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

import SwiftSyntax

final class TypeDiscoveryVisitor: SyntaxVisitor {
    var discoveredTypes: [TypeInfo] = []
    let filePath: String
    private var extensionNestingLevel: Int = 0
    private var typeNestingLevel: Int = 0
    private var currentNamespace: [String] = []

    init(filePath: String) {
        self.filePath = filePath
        super.init(viewMode: .sourceAccurate)
    }

    override func visit(_ node: ExtensionDeclSyntax) -> SyntaxVisitorContinueKind {
        // Check if this is a namespace extension (like extension Temporal.Api.Activity.V1)
        if extensionNestingLevel == 0, let namespace = extractNamespace(from: node.extendedType) {
            currentNamespace = namespace
        }
        extensionNestingLevel += 1
        return .visitChildren
    }

    override func visitPost(_ node: ExtensionDeclSyntax) {
        extensionNestingLevel -= 1
        if extensionNestingLevel == 0 {
            currentNamespace = []
        }
    }

    private func extractNamespace(from type: TypeSyntax) -> [String]? {
        var components: [String] = []
        var currentType: TypeSyntax = type

        // Walk up the member type chain
        while let memberType = currentType.as(MemberTypeSyntax.self) {
            components.insert(memberType.name.text, at: 0)
            currentType = memberType.baseType
        }

        // Get the base type
        if let identifierType = currentType.as(IdentifierTypeSyntax.self) {
            components.insert(identifierType.name.text, at: 0)
        }

        return components.isEmpty ? nil : components
    }

    override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
        // Only register types that are:
        // - At typeNestingLevel 0 (top-level within their context) AND
        // - Either at extensionNestingLevel 0 (file-level) OR extensionNestingLevel 1 with a namespace (in a namespace extension)
        let shouldRegister = typeNestingLevel == 0 && ((extensionNestingLevel == 0) || (extensionNestingLevel == 1 && !currentNamespace.isEmpty))

        if shouldRegister,
            let typeInfo = extractTypeInfo(
                name: node.name.text,
                modifiers: node.modifiers,
                kind: .struct
            )
        {
            discoveredTypes.append(typeInfo)
        }
        typeNestingLevel += 1
        return .visitChildren
    }

    override func visitPost(_ node: StructDeclSyntax) {
        typeNestingLevel -= 1
    }

    override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
        let shouldRegister = typeNestingLevel == 0 && ((extensionNestingLevel == 0) || (extensionNestingLevel == 1 && !currentNamespace.isEmpty))

        if shouldRegister,
            let typeInfo = extractTypeInfo(
                name: node.name.text,
                modifiers: node.modifiers,
                kind: .enum
            )
        {
            discoveredTypes.append(typeInfo)
        }
        typeNestingLevel += 1
        return .visitChildren
    }

    override func visitPost(_ node: EnumDeclSyntax) {
        typeNestingLevel -= 1
    }

    override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
        let shouldRegister = typeNestingLevel == 0 && ((extensionNestingLevel == 0) || (extensionNestingLevel == 1 && !currentNamespace.isEmpty))

        if shouldRegister,
            let typeInfo = extractTypeInfo(
                name: node.name.text,
                modifiers: node.modifiers,
                kind: .class
            )
        {
            discoveredTypes.append(typeInfo)
        }
        typeNestingLevel += 1
        return .visitChildren
    }

    override func visitPost(_ node: ClassDeclSyntax) {
        typeNestingLevel -= 1
    }

    override func visit(_ node: ActorDeclSyntax) -> SyntaxVisitorContinueKind {
        let shouldRegister = typeNestingLevel == 0 && ((extensionNestingLevel == 0) || (extensionNestingLevel == 1 && !currentNamespace.isEmpty))

        if shouldRegister,
            let typeInfo = extractTypeInfo(
                name: node.name.text,
                modifiers: node.modifiers,
                kind: .actor
            )
        {
            discoveredTypes.append(typeInfo)
        }
        typeNestingLevel += 1
        return .visitChildren
    }

    override func visitPost(_ node: ActorDeclSyntax) {
        typeNestingLevel -= 1
    }

    private func extractTypeInfo(
        name: String,
        modifiers: DeclModifierListSyntax,
        kind: DeclKind
    ) -> TypeInfo? {
        let namespace: [String]
        let shortName: String
        let oldName: String

        if !currentNamespace.isEmpty {
            // We're inside a namespace extension - reconstruct old name
            namespace = currentNamespace
            shortName = name
            oldName = (currentNamespace + [name]).joined(separator: "_")
        } else {
            // Try to parse as old-style underscore name
            guard let parsed = NamespaceParser.parse(typeName: name) else {
                return nil
            }
            namespace = parsed.namespace
            shortName = parsed.shortName
            oldName = name
        }

        // Extract access level from modifiers
        let accessLevel = extractAccessLevel(from: modifiers)

        // Skip fileprivate types - they don't get wrapped
        guard accessLevel != .fileprivate else {
            return nil
        }

        return TypeInfo(
            oldName: oldName,
            namespace: namespace,
            shortName: shortName,
            accessLevel: accessLevel,
            declarationKind: kind,
            filePath: filePath
        )
    }

    private func extractAccessLevel(from modifiers: DeclModifierListSyntax) -> AccessLevel {
        for modifier in modifiers {
            switch modifier.name.tokenKind {
            case .keyword(.public):
                return .public
            case .keyword(.package):
                return .package
            case .keyword(.fileprivate):
                return .fileprivate
            default:
                continue
            }
        }
        return .package  // Default to package if no access level specified
    }
}
