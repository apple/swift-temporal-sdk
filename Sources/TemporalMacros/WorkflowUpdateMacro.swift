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

public struct WorkflowUpdateMacro: PeerMacro {
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
            throw MacroError(message: "@WorkflowUpdate can only be used inside a workflow class")
        }

        // Only methods can be updates
        guard let functionDecl = declaration.as(FunctionDeclSyntax.self) else {
            throw MacroError(message: "@WorkflowUpdate can only be applied to methods")
        }

        // Updates must not return anything so we fallback to Void
        let returnType = functionDecl.signature.returnClause?.type.description ?? "Void"
        let parameters = functionDecl.signature.parameterClause.parameters

        // Updates must have one parameter (the input)
        guard parameters.count == 1 else {
            throw MacroError(message: "Workflow updates must have one parameter")
        }

        // The parameter must be the input
        guard parameters.first?.firstName.text == "input" else {
            throw MacroError(message: "Workflow update parameter must be called 'input'")
        }

        let input = parameters.first!

        let rawAccessModifier = functionDecl.modifiers.accessModifierPrefix(supportedModifiers: .allAccessModifiers)

        var nameDecl: DeclSyntax?
        var descriptionDecl: DeclSyntax?
        var unfinishedPolicyDecl: DeclSyntax?
        if let name = node.stringLiteralValueForArgument(named: "name") {
            nameDecl = "\(raw: rawAccessModifier)static var name: String { \(name) }"
        }
        if let description = node.stringLiteralValueForArgument(named: "description") {
            descriptionDecl = "\(raw: rawAccessModifier)static var description: String? { \(description) }"
        }
        if let policyName = node.memberAccessNameForArgument(named: "unfinishedPolicy") {
            unfinishedPolicyDecl = "\(raw: rawAccessModifier)static var unfinishedPolicy: HandlerUnfinishedPolicy { .\(raw: policyName) }"
        }

        let validatorName = node.stringValueForArgument(named: "validator")
        let updateName = functionDecl.name.text.capitalizingFirst()

        let initParams: String
        let initBody: String
        var validatorDecl: DeclSyntax?
        if validatorName != nil {
            initParams =
                "run: @Sendable @escaping (Workflow, Input) async throws -> Output, validate: @Sendable @escaping (Workflow, Input) throws -> Void"
            initBody = """
                self._run = run
                            self._validate = validate
                """
            validatorDecl = """
                let _validate: @Sendable (Workflow, Input) throws -> Void
                        \(raw: rawAccessModifier)func validateInput(workflow: Workflow, _ input: Input) throws {
                            try self._validate(workflow, input)
                        }
                """
        } else {
            initParams = "run: @Sendable @escaping (Workflow, Input) async throws -> Output"
            initBody = "self._run = run"
        }

        let staticVarBody: String
        if let validatorName = validatorName {
            staticVarBody =
                "\(updateName)(run: { try await $0.\(functionDecl.name.text)(input: $1) }, validate: { try $0.\(validatorName)(input: $1) })"
        } else {
            staticVarBody = "\(updateName)(run: { try await $0.\(functionDecl.name.text)(input: $1) })"
        }

        return [
            """
            \(raw: rawAccessModifier)struct \(raw: updateName): WorkflowUpdateDefinition {
                \(raw: rawAccessModifier)typealias Input = \(input.type)
                \(raw: rawAccessModifier)typealias Output = \(raw: returnType)
                \(raw: rawAccessModifier)typealias Workflow = \(parentClass.name)

                let _run: @Sendable (Workflow, Input) async throws -> Output
                init(\(raw: initParams)) {
                    \(raw: initBody)
                }
                \(raw: rawAccessModifier)func run(workflow: Workflow, input: Input) async throws -> Output{
                    try await self._run(workflow, input)
                }
                \(nameDecl)
                \(descriptionDecl)
                \(unfinishedPolicyDecl)
                \(validatorDecl)
            }
            """,
            """
            static var \(raw: functionDecl.name.text): \(raw: updateName) {
                \(raw: staticVarBody)
            }
            """,
        ]
    }
}
