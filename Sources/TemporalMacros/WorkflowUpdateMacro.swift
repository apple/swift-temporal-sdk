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

/// Macro implementation for the `@WorkflowUpdate` attribute.
public struct WorkflowUpdateMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        // Can only be used inside a workflow struct
        guard let parent = context.lexicalContext.first else {
            throw MacroError(message: "@WorkflowUpdate can only be used inside a workflow")
        }

        let parentName: String
        guard let structDecl = parent.as(StructDeclSyntax.self),
            structDecl.attributes.contains(where: { element in
                element.as(AttributeSyntax.self)?.attributeName.as(IdentifierTypeSyntax.self)?.description == "Workflow"
            })
        else {
            throw MacroError(message: "@WorkflowUpdate can only be used inside a workflow struct")
        }
        parentName = structDecl.name.text

        // Only methods can be updates
        guard let functionDecl = declaration.as(FunctionDeclSyntax.self) else {
            throw MacroError(message: "@WorkflowUpdate can only be applied to methods")
        }

        // Updates must not return anything so we fallback to Void
        let returnType = functionDecl.signature.returnClause?.type.description ?? "Void"
        let parameters = functionDecl.signature.parameterClause.parameters

        // Updates must have one or two parameters (input, and optionally context)
        let hasContextParam: Bool
        if parameters.count == 2 {
            guard parameters.first?.firstName.text == "context" else {
                throw MacroError(message: "Workflow update first parameter must be called 'context' with type 'WorkflowContext<Self>'")
            }
            guard parameters.dropFirst().first?.firstName.text == "input" else {
                throw MacroError(message: "Workflow update second parameter must be called 'input' with a Sendable type")
            }
            hasContextParam = true
        } else if parameters.count == 1 {
            guard parameters.first?.firstName.text == "input" else {
                throw MacroError(message: "Workflow update parameter must be called 'input' with a Sendable type")
            }
            hasContextParam = false
        } else {
            throw MacroError(message: "Workflow updates must have one parameter 'input' or two parameters 'context' and 'input'")
        }

        let input = hasContextParam ? parameters.dropFirst().first! : parameters.first!

        let throwingUpdate = functionDecl.signature.effectSpecifiers?.throwsClause?.throwsSpecifier.presence == .present
        let asyncUpdate = functionDecl.signature.effectSpecifiers?.asyncSpecifier?.presence == .present
        let isMutating = functionDecl.modifiers.contains { $0.name.tokenKind == .keyword(.mutating) }

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
                "run: @Sendable @escaping (Workflow, WorkflowContext<Workflow>, Input) async throws -> Output, validate: @Sendable @escaping (Workflow, Input) throws -> Void"
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
            initParams = "run: @Sendable @escaping (Workflow, WorkflowContext<Workflow>, Input) async throws -> Output"
            initBody = "self._run = run"
        }

        // For mutating updates, the closure needs a mutable copy of the workflow.
        // Since @_WorkflowState uses reference-backed boxes, mutations on the copy
        // are visible through the shared boxes.
        let tryKeyword = throwingUpdate ? "try " : ""
        let awaitKeyword = asyncUpdate ? "await " : ""
        let returnKeyword = returnType != "Void" ? "return " : ""

        let runClosureBody: String
        switch (isMutating, hasContextParam) {
        case (true, true):
            runClosureBody =
                "{ workflow, context, input in var workflow = workflow; \(returnKeyword)\(tryKeyword)\(awaitKeyword)workflow.\(functionDecl.name.text)(context: context, input: input) }"
        case (true, false):
            runClosureBody =
                "{ workflow, _, input in var workflow = workflow; \(returnKeyword)\(tryKeyword)\(awaitKeyword)workflow.\(functionDecl.name.text)(input: input) }"
        case (false, true):
            runClosureBody =
                "{ workflow, context, input in \(returnKeyword)\(tryKeyword)\(awaitKeyword)workflow.\(functionDecl.name.text)(context: context, input: input) }"
        case (false, false):
            runClosureBody =
                "{ workflow, _, input in \(returnKeyword)\(tryKeyword)\(awaitKeyword)workflow.\(functionDecl.name.text)(input: input) }"
        }

        let staticVarBody: String
        if let validatorName = validatorName {
            staticVarBody =
                "\(updateName)(run: \(runClosureBody), validate: { try $0.\(validatorName)(input: $1) })"
        } else {
            staticVarBody = "\(updateName)(run: \(runClosureBody))"
        }

        return [
            """
            \(raw: rawAccessModifier)struct \(raw: updateName): WorkflowUpdateDefinition {
                \(raw: rawAccessModifier)typealias Input = \(input.type)
                \(raw: rawAccessModifier)typealias Output = \(raw: returnType)
                \(raw: rawAccessModifier)typealias Workflow = \(raw: parentName)

                let _run: @Sendable (Workflow, WorkflowContext<Workflow>, Input) async throws -> Output
                init(\(raw: initParams)) {
                    \(raw: initBody)
                }
                \(raw: rawAccessModifier)func run(workflow: Workflow, context: WorkflowContext<Workflow>, input: Input) async throws -> Output{
                    try await self._run(workflow, context, input)
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
