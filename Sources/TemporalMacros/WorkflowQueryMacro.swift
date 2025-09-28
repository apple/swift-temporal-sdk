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

import Foundation
import SwiftSyntax
import SwiftSyntaxMacros

public struct WorkflowQueryMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        // Can only be used inside a workflow
        guard let parent = context.lexicalContext.first,
            let parentClass = parent.as(ClassDeclSyntax.self),
            parentClass.attributes.contains(where: { element in
                element.as(AttributeSyntax.self)?.attributeName.as(IdentifierTypeSyntax.self)?.description == "Workflow"
            })
        else {
            throw MacroError(message: "@WorkflowQuery can only be used inside a workflow class")
        }

        // Only methods can be queries
        guard let functionDecl = declaration.as(FunctionDeclSyntax.self) else {
            throw MacroError(message: "@WorkflowQuery can only be applied to methods")
        }

        // Queries must return something
        guard let returnClause = functionDecl.signature.returnClause,
            returnClause.type.as(IdentifierTypeSyntax.self)?.name.text != "Void"
        else {
            throw MacroError(message: "Workflow queries must return a non-Void value")
        }

        let parameters = functionDecl.signature.parameterClause.parameters

        // Queries must have one parameter (the input)
        guard parameters.count == 1 else {
            throw MacroError(message: "Workflow queries must have one parameter")
        }

        // The parameter must be the input
        guard parameters.first?.firstName.text == "input" else {
            throw MacroError(message: "Workflow query parameter must be called 'input'")
        }

        let input = parameters.first!

        let throwingQuery = functionDecl.signature.effectSpecifiers?.throwsClause?.throwsSpecifier.presence == .present

        let rawAccessModifier = functionDecl.modifiers.accessModifierPrefix(supportedModifiers: .allAccessModifiers)

        var nameDecl: DeclSyntax?
        var descriptionDecl: DeclSyntax?
        if let name = node.stringLiteralValueForArgument(named: "name") {
            nameDecl = "\(raw: rawAccessModifier)static var name: String { \(name) }"
        }
        if let description = node.stringLiteralValueForArgument(named: "description") {
            descriptionDecl = "\(raw: rawAccessModifier)static var description: String? { \(description) }"
        }

        let queryName = functionDecl.name.text.capitalizingFirst()
        return [
            """
            \(raw: rawAccessModifier)struct \(raw: queryName): WorkflowQueryDefinition {
                \(raw: rawAccessModifier)typealias Input = \(input.type)
                \(raw: rawAccessModifier)typealias Output = \(returnClause.type)
                \(raw: rawAccessModifier)typealias Workflow = \(parentClass.name)
                
                let _run: @Sendable (Workflow, Input) throws -> Output
                init(run: @Sendable @escaping (Workflow, Input) throws -> Output) {
                    self._run = run
                }
                \(raw: rawAccessModifier)func run(workflow: Workflow, input: Input) throws -> Output {
                    try self._run(workflow, input)
                }
                \(nameDecl)
                \(descriptionDecl)
            }
            """,
            """
            static var \(raw: functionDecl.name.text): \(raw: queryName) {
                \(raw: queryName)(run: { \(raw: throwingQuery ? "try" : "") $0.\(raw: functionDecl.name.text)(input: $1) })
            }
            """,
        ]
    }
}
