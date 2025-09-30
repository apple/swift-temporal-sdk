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
        // Can only be used inside a workflow
        guard let parent = context.lexicalContext.first,
            let parentClass = parent.as(ClassDeclSyntax.self),
            parentClass.attributes.contains(where: { element in
                element.as(AttributeSyntax.self)?.attributeName.as(IdentifierTypeSyntax.self)?.description == "Workflow"
            })
        else {
            throw MacroError(message: "@WorkflowSignal can only be used inside a workflow class")
        }

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

        // Signals must have one parameter (the input)
        guard parameters.count == 1 else {
            throw MacroError(message: "Workflow signals must have one parameter")
        }

        // The parameter must be the input
        guard parameters.first?.firstName.text == "input" else {
            throw MacroError(message: "Workflow signal parameter must be called 'input'")
        }

        let input = parameters.first!

        let throwingSignal = functionDecl.signature.effectSpecifiers?.throwsClause?.throwsSpecifier.presence == .present
        let asyncSignal = functionDecl.signature.effectSpecifiers?.asyncSpecifier?.presence == .present

        let rawAccessModifier = functionDecl.modifiers.accessModifierPrefix(supportedModifiers: .allAccessModifiers)

        var nameDecl: DeclSyntax?
        var descriptionDecl: DeclSyntax?
        if let name = node.stringLiteralValueForArgument(named: "name") {
            nameDecl = "\(raw: rawAccessModifier)static var name: String { \(name) }"
        }
        if let description = node.stringLiteralValueForArgument(named: "description") {
            descriptionDecl = "\(raw: rawAccessModifier)static var description: String? { \(description) }"
        }

        let signalName = functionDecl.name.text.capitalizingFirst()
        return [
            """
            \(raw: rawAccessModifier)struct \(raw: signalName): WorkflowSignalDefinition {
                \(raw: rawAccessModifier)typealias Input = \(input.type)
                \(raw: rawAccessModifier)typealias Workflow = \(parentClass.name)
                
                let _run: @Sendable (Workflow, Input) async throws -> Void
                init(run: @Sendable @escaping (Workflow, Input) async throws -> Void) {
                    self._run = run
                }
                \(raw: rawAccessModifier)func run(workflow: Workflow, input: Input) async throws {
                    try await self._run(workflow, input)
                }
                \(nameDecl)
                \(descriptionDecl)
            }
            """,
            """
            static var \(raw: functionDecl.name.text): \(raw: signalName) {
                \(raw: signalName)(run: { \(raw: throwingSignal ? "try" : "") \(raw: asyncSignal ? "await" : "") $0.\(raw: functionDecl.name.text)(input: $1) })
            }
            """,
        ]
    }
}
