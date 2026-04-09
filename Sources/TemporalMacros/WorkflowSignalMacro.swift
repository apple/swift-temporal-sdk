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

public struct WorkflowSignalMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        // Can only be used inside a workflow struct
        guard let parent = context.lexicalContext.first else {
            throw MacroError(message: "@WorkflowSignal can only be used inside a workflow")
        }

        let parentName: String
        guard let structDecl = parent.as(StructDeclSyntax.self),
            structDecl.attributes.contains(where: { element in
                element.as(AttributeSyntax.self)?.attributeName.as(IdentifierTypeSyntax.self)?.description == "Workflow"
            })
        else {
            throw MacroError(message: "@WorkflowSignal can only be used inside a workflow struct")
        }
        parentName = structDecl.name.text

        // Only methods can be signals
        guard let functionDecl = declaration.as(FunctionDeclSyntax.self) else {
            throw MacroError(message: "@WorkflowSignal can only be applied to methods")
        }

        // Signals cannot return anything
        if let returnClause = functionDecl.signature.returnClause,
            returnClause.type.as(IdentifierTypeSyntax.self)?.name.text != "Void"
        {
            throw MacroError(message: "Workflow signals can not return a value")
        }

        let parameters = functionDecl.signature.parameterClause.parameters

        // Signals must have one or two parameters (input, and optionally context)
        let hasContextParam: Bool
        if parameters.count == 2 {
            guard parameters.first?.firstName.text == "context" else {
                throw MacroError(message: "Workflow signal first parameter must be called 'context' with type 'WorkflowContext<Self>'")
            }
            guard parameters.dropFirst().first?.firstName.text == "input" else {
                throw MacroError(message: "Workflow signal second parameter must be called 'input' with a Sendable type")
            }
            hasContextParam = true
        } else if parameters.count == 1 {
            guard parameters.first?.firstName.text == "input" else {
                throw MacroError(message: "Workflow signal parameter must be called 'input' with a Sendable type")
            }
            hasContextParam = false
        } else {
            throw MacroError(message: "Workflow signals must have one parameter 'input' or two parameters 'context' and 'input'")
        }

        let input = hasContextParam ? parameters.dropFirst().first! : parameters.first!

        let throwingSignal = functionDecl.signature.effectSpecifiers?.throwsClause?.throwsSpecifier.presence == .present
        let asyncSignal = functionDecl.signature.effectSpecifiers?.asyncSpecifier?.presence == .present
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

        let signalName = functionDecl.name.text.capitalizingFirst()

        // For mutating signals, the closure needs a mutable copy of the workflow.
        // Since @_WorkflowState uses reference-backed boxes, mutations on the copy
        // are visible through the shared boxes.
        let closureBody: String =
            switch (isMutating, hasContextParam) {
            case (true, true):
                "{ workflow, context, input in var workflow = workflow; \(throwingSignal ? "try" : "") \(asyncSignal ? "await" : "") workflow.\(functionDecl.name.text)(context: context, input: input) }"
            case (true, false):
                "{ workflow, _, input in var workflow = workflow; \(throwingSignal ? "try" : "") \(asyncSignal ? "await" : "") workflow.\(functionDecl.name.text)(input: input) }"
            case (false, true):
                "{ workflow, context, input in \(throwingSignal ? "try" : "") \(asyncSignal ? "await" : "") workflow.\(functionDecl.name.text)(context: context, input: input) }"
            case (false, false):
                "{ workflow, _, input in \(throwingSignal ? "try" : "") \(asyncSignal ? "await" : "") workflow.\(functionDecl.name.text)(input: input) }"
            }

        return [
            """
            \(raw: rawAccessModifier)struct \(raw: signalName): WorkflowSignalDefinition {
                \(raw: rawAccessModifier)typealias Input = \(input.type)
                \(raw: rawAccessModifier)typealias Workflow = \(raw: parentName)

                let _run: @Sendable (Workflow, WorkflowContext<Workflow>, Input) async throws -> Void
                init(run: @Sendable @escaping (Workflow, WorkflowContext<Workflow>, Input) async throws -> Void) {
                    self._run = run
                }
                \(raw: rawAccessModifier)func run(workflow: Workflow, context: WorkflowContext<Workflow>, input: Input) async throws {
                    try await self._run(workflow, context, input)
                }
                \(nameDecl)
                \(descriptionDecl)
                \(unfinishedPolicyDecl)
            }
            """,
            """
            static var \(raw: functionDecl.name.text): \(raw: signalName) {
                \(raw: signalName)(run: \(raw: closureBody))
            }
            """,
        ]
    }
}
