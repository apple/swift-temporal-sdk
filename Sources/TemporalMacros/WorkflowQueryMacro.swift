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

import Foundation
import SwiftSyntax
import SwiftSyntaxMacros

/// Macro implementation for the `@WorkflowQuery` attribute.
public struct WorkflowQueryMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        // Can only be used inside a workflow struct
        guard let parent = context.lexicalContext.first else {
            throw MacroError(message: "@WorkflowQuery can only be used inside a workflow")
        }

        let parentName: String
        guard let structDecl = parent.as(StructDeclSyntax.self),
            structDecl.attributes.contains(where: { element in
                element.as(AttributeSyntax.self)?.attributeName.as(IdentifierTypeSyntax.self)?.description == "Workflow"
            })
        else {
            throw MacroError(message: "@WorkflowQuery can only be used inside a workflow struct")
        }
        parentName = structDecl.name.text

        if let functionDecl = declaration.as(FunctionDeclSyntax.self) {
            return try expandMethodQuery(
                node: node,
                functionDecl: functionDecl,
                parentName: parentName
            )
        } else if let variableDecl = declaration.as(VariableDeclSyntax.self) {
            return try expandPropertyQuery(
                node: node,
                variableDecl: variableDecl,
                parentName: parentName
            )
        } else {
            throw MacroError(message: "@WorkflowQuery can only be applied to methods or properties")
        }
    }

    // MARK: - Method Queries

    private static func expandMethodQuery(
        node: AttributeSyntax,
        functionDecl: FunctionDeclSyntax,
        parentName: String
    ) throws -> [DeclSyntax] {
        // Queries must return something
        guard let returnClause = functionDecl.signature.returnClause,
            returnClause.type.as(IdentifierTypeSyntax.self)?.name.text != "Void"
        else {
            throw MacroError(message: "Workflow queries must return a non-Void value")
        }

        let parameters = functionDecl.signature.parameterClause.parameters

        // Queries must have one or two parameters (input, and optionally context)
        let hasContextParam: Bool
        if parameters.count == 2 {
            guard parameters.first?.firstName.text == "context" else {
                throw MacroError(
                    message: "Workflow query first parameter must be called 'context' with type 'WorkflowContextView'"
                )
            }
            guard parameters.dropFirst().first?.firstName.text == "input" else {
                throw MacroError(
                    message: "Workflow query second parameter must be called 'input' with a Sendable type"
                )
            }
            hasContextParam = true
        } else if parameters.count == 1 {
            guard parameters.first?.firstName.text == "input" else {
                throw MacroError(
                    message: "Workflow query parameter must be called 'input' with a Sendable type"
                )
            }
            hasContextParam = false
        } else {
            throw MacroError(
                message: "Workflow queries must have one parameter 'input' or two parameters 'context' and 'input'"
            )
        }

        let input = hasContextParam ? parameters.dropFirst().first! : parameters.first!

        let throwingQuery =
            functionDecl.signature.effectSpecifiers?.throwsClause?.throwsSpecifier.presence == .present

        let rawAccessModifier = functionDecl.modifiers.accessModifierPrefix(
            supportedModifiers: .allAccessModifiers
        )

        var nameDecl: DeclSyntax?
        var descriptionDecl: DeclSyntax?
        if let name = node.stringLiteralValueForArgument(named: "name") {
            nameDecl = "\(raw: rawAccessModifier)static var name: String { \(name) }"
        }
        if let description = node.stringLiteralValueForArgument(named: "description") {
            descriptionDecl =
                "\(raw: rawAccessModifier)static var description: String? { \(description) }"
        }

        let queryName = functionDecl.name.text.capitalizingFirst()

        let closureBody: String
        if hasContextParam {
            closureBody =
                "{ workflow, view, input in \(throwingQuery ? "try" : "") workflow.\(functionDecl.name.text)(context: view, input: input) }"
        } else {
            closureBody =
                "{ workflow, _, input in \(throwingQuery ? "try" : "") workflow.\(functionDecl.name.text)(input: input) }"
        }

        return [
            """
            \(raw: rawAccessModifier)struct \(raw: queryName): WorkflowQueryDefinition {
                \(raw: rawAccessModifier)typealias Input = \(input.type)
                \(raw: rawAccessModifier)typealias Output = \(returnClause.type)
                \(raw: rawAccessModifier)typealias Workflow = \(raw: parentName)

                let _run: @Sendable (Workflow, WorkflowContextView, Input) throws -> Output
                init(run: @Sendable @escaping (Workflow, WorkflowContextView, Input) throws -> Output) {
                    self._run = run
                }
                \(raw: rawAccessModifier)func run(workflow: Workflow, view: WorkflowContextView, input: Input) throws -> Output {
                    try self._run(workflow, view, input)
                }
                \(nameDecl)
                \(descriptionDecl)
            }
            """,
            """
            static var \(raw: functionDecl.name.text): \(raw: queryName) {
                \(raw: queryName)(run: \(raw: closureBody))
            }
            """,
        ]
    }

    // MARK: - Property Queries

    private static func expandPropertyQuery(
        node: AttributeSyntax,
        variableDecl: VariableDeclSyntax,
        parentName: String
    ) throws -> [DeclSyntax] {
        guard let binding = variableDecl.bindings.first,
            let identifierPattern = binding.pattern.as(IdentifierPatternSyntax.self)
        else {
            throw MacroError(message: "@WorkflowQuery property must have an identifier")
        }

        let propertyName = identifierPattern.identifier.text

        guard let typeAnnotation = binding.typeAnnotation else {
            throw MacroError(message: "@WorkflowQuery property must have an explicit type annotation")
        }
        let propertyType = typeAnnotation.type

        let accessModifier = variableDecl.modifiers.accessModifierPrefix(
            supportedModifiers: .allAccessModifiers
        )

        var nameDecl: DeclSyntax?
        var descriptionDecl: DeclSyntax?
        if let name = node.stringLiteralValueForArgument(named: "name") {
            nameDecl = "\(accessModifier)static var name: String { \(name) }"
        }
        if let description = node.stringLiteralValueForArgument(named: "description") {
            descriptionDecl =
                "\(accessModifier)static var description: String? { \(description) }"
        }

        let queryName = propertyName.capitalizingFirst()

        return [
            """
            \(accessModifier)struct \(raw: queryName): WorkflowQueryDefinition {
                \(accessModifier)typealias Input = Void
                \(accessModifier)typealias Output = \(propertyType)
                \(accessModifier)typealias Workflow = \(raw: parentName)

                let _run: @Sendable (Workflow, WorkflowContextView, Input) throws -> Output
                init(run: @Sendable @escaping (Workflow, WorkflowContextView, Input) throws -> Output) {
                    self._run = run
                }
                \(accessModifier)func run(workflow: Workflow, view: WorkflowContextView, input: Input) throws -> Output {
                    try self._run(workflow, view, input)
                }
                \(nameDecl)
                \(descriptionDecl)
            }
            """,
            """
            static var \(raw: propertyName): \(raw: queryName) {
                \(raw: queryName)(run: { workflow, _, _ in workflow.\(raw: propertyName) })
            }
            """,
        ]
    }
}
