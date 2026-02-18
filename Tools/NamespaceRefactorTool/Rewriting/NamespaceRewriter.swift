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

import Foundation
import SwiftParser
import SwiftSyntax
import SwiftSyntaxBuilder

// Swift reserved keywords that need to be escaped with backticks
let swiftReservedKeywords: Set<String> = [
    // Declaration keywords
    "associatedtype", "class", "deinit", "enum", "extension", "fileprivate", "func", "import", "init",
    "inout", "internal", "let", "open", "operator", "private", "precedencegroup", "protocol", "public",
    "rethrows", "static", "struct", "subscript", "typealias", "var",

    // Statement keywords
    "break", "case", "catch", "continue", "default", "defer", "do", "else", "fallthrough", "for",
    "guard", "if", "in", "repeat", "return", "throw", "switch", "where", "while",

    // Expression and type keywords
    "Any", "as", "await", "catch", "false", "is", "nil", "self", "Self", "super", "throw", "throws",
    "true", "try",

    // Pattern keywords
    "_",

    // Keywords reserved in particular contexts
    "Protocol", "Type", "associativity", "convenience", "didSet", "dynamic", "final", "get", "indirect",
    "infix", "lazy", "left", "mutating", "none", "nonmutating", "optional", "override", "postfix",
    "precedence", "prefix", "required", "right", "set", "some", "unowned", "weak", "willSet",
]

private func escapeIfNeeded(_ name: String) -> String {
    if swiftReservedKeywords.contains(name) {
        return "`\(name)`"
    }
    return name
}

final class NamespaceRewriter {
    let typeRegistry: TypeRegistry

    init(typeRegistry: TypeRegistry) {
        self.typeRegistry = typeRegistry
    }

    func transform(source: String) -> String {
        // Step 1: Parse the source
        let syntax = Parser.parse(source: source)

        // Step 2: Wrap type declarations using SwiftSyntax
        let rewriter = DeclarationWrapper(typeRegistry: typeRegistry)
        let wrappedSyntax = rewriter.rewrite(syntax)

        // Step 3: Convert back to string
        var result = wrappedSyntax.description

        // Step 4: Replace type references using string replacement
        // Sort types by name length (longest first) to avoid partial matches
        let sortedTypes = typeRegistry.sortedByLength()

        for typeInfo in sortedTypes {
            let oldName = typeInfo.oldName
            let newName = typeInfo.namespacedName

            // Use regex to replace whole-word matches only
            let pattern = "\\b\(NSRegularExpression.escapedPattern(for: oldName))\\b"
            if let regex = try? NSRegularExpression(pattern: pattern) {
                let nsRange = NSRange(result.startIndex..., in: result)
                result = regex.stringByReplacingMatches(
                    in: result,
                    range: nsRange,
                    withTemplate: newName
                )
            }
        }

        return result
    }
}

// Separate rewriter just for wrapping declarations
private class DeclarationWrapper: SyntaxRewriter {
    let typeRegistry: TypeRegistry
    var wrappedDecls: Set<String> = []

    init(typeRegistry: TypeRegistry) {
        self.typeRegistry = typeRegistry
        super.init(viewMode: .sourceAccurate)
    }

    override func visit(_ node: StructDeclSyntax) -> DeclSyntax {
        return wrapIfNeeded(node, name: node.name.text) { name in
            node.with(\.name, .identifier(name))
        }
    }

    override func visit(_ node: EnumDeclSyntax) -> DeclSyntax {
        return wrapIfNeeded(node, name: node.name.text) { name in
            node.with(\.name, .identifier(name))
        }
    }

    override func visit(_ node: ClassDeclSyntax) -> DeclSyntax {
        return wrapIfNeeded(node, name: node.name.text) { name in
            node.with(\.name, .identifier(name))
        }
    }

    override func visit(_ node: ActorDeclSyntax) -> DeclSyntax {
        return wrapIfNeeded(node, name: node.name.text) { name in
            node.with(\.name, .identifier(name))
        }
    }

    override func visit(_ node: ExtensionDeclSyntax) -> DeclSyntax {
        guard let identifierType = node.extendedType.as(IdentifierTypeSyntax.self),
            let typeInfo = typeRegistry.lookup(oldName: identifierType.name.text)
        else {
            return DeclSyntax(node)
        }

        // For extensions, update the extended type to use the full namespaced path
        // Don't wrap in another extension - that's invalid Swift
        let fullNamespacedType = buildNamespacedType(components: typeInfo.namespace + [typeInfo.shortName])

        let updatedExtension = node.with(\.extendedType, fullNamespacedType)

        return DeclSyntax(updatedExtension)
    }

    private func wrapIfNeeded<T: DeclSyntaxProtocol>(
        _ node: T,
        name: String,
        renamer: (String) -> T
    ) -> DeclSyntax {
        guard let typeInfo = typeRegistry.lookup(oldName: name),
            !wrappedDecls.contains(name)
        else {
            return DeclSyntax(node)
        }

        wrappedDecls.insert(name)

        let renamedDecl = renamer(typeInfo.shortName)
        return wrapInExtension(
            namespace: typeInfo.namespaceString,
            member: DeclSyntax(renamedDecl)
        )
    }

    private func wrapInExtension(namespace: String, member: DeclSyntax) -> DeclSyntax {
        let components = namespace.split(separator: ".").map(String.init)
        let extendedType = buildNamespacedType(components: components)

        // Indent the member by 2 spaces
        let indentedMember = indentDeclaration(member, by: 2)

        let extensionDecl = ExtensionDeclSyntax(
            leadingTrivia: .newline,
            extensionKeyword: .keyword(.extension, trailingTrivia: .space),
            extendedType: extendedType,
            memberBlock: MemberBlockSyntax(
                leftBrace: .leftBraceToken(leadingTrivia: .space),
                members: MemberBlockItemListSyntax([
                    MemberBlockItemSyntax(
                        leadingTrivia: .newline,
                        decl: indentedMember,
                        trailingTrivia: .newline
                    )
                ]),
                rightBrace: .rightBraceToken()
            )
        )

        return DeclSyntax(extensionDecl)
    }

    /// Indents all lines of a declaration by the specified number of spaces.
    private func indentDeclaration(_ decl: DeclSyntax, by spaces: Int) -> DeclSyntax {
        let indentation = String(repeating: " ", count: spaces)
        let declString = decl.description

        // Split into lines and indent each line
        let lines = declString.split(separator: "\n", omittingEmptySubsequences: false)
        let indentedLines = lines.map { line in
            // Don't indent empty lines
            if line.trimmingCharacters(in: .whitespaces).isEmpty {
                return String(line)
            }
            return indentation + line
        }

        let indentedString = indentedLines.joined(separator: "\n")

        // Parse the indented string back into a full source file, then extract the first declaration
        let sourceFile = Parser.parse(source: indentedString)
        if let firstDecl = sourceFile.statements.first?.item.as(DeclSyntax.self) {
            return firstDecl
        }

        // Fallback: return original if parsing fails
        return decl
    }

    private func buildNamespacedType(components: [String]) -> TypeSyntax {
        guard !components.isEmpty else {
            fatalError("Cannot build type from empty components")
        }

        var result: TypeSyntax = TypeSyntax(
            IdentifierTypeSyntax(name: .identifier(escapeIfNeeded(components[0])))
        )

        for component in components.dropFirst() {
            result = TypeSyntax(
                MemberTypeSyntax(
                    baseType: result,
                    period: .periodToken(),
                    name: .identifier(escapeIfNeeded(component))
                )
            )
        }

        return result
    }
}
