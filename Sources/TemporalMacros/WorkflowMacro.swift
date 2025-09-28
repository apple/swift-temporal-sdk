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

import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

public struct WorkflowMacro: ExtensionMacro, MemberMacro, MemberAttributeMacro {
    struct UnexpectedInitWarning: DiagnosticMessage {
        var message: String {
            "Unexpected workflow initializer not accepting an 'input:' parameter as mandated by the 'WorkflowDefinition' protocol."
        }
        var diagnosticID: MessageID { MessageID(domain: "WorkflowMacro", id: "unexpected_init") }
        var severity: DiagnosticSeverity { .warning }
    }

    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        // The protocol conformance to `WorkflowDefinition`
        guard let workflowName = node.stringLiteralValueForArgument(named: "name") else {
            return [try .init("extension \(type): WorkflowDefinition {}")]
        }
        let rawAccessModifier = declaration.modifiers.accessModifierPrefix(supportedModifiers: .workflowDefinitionAccessModifiers)

        // The first argument to our @Workflow macro is the custom name
        return [
            try .init(
                """
                extension \(type): WorkflowDefinition {
                    \(raw: rawAccessModifier)static var name: String { \(workflowName) }
                }
                """
            )
        ]
    }

    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let classDecl = declaration.as(ClassDeclSyntax.self) else {
            throw MacroError(message: "Workflow macro can only be applied to classes")
        }

        var signalNames = [String]()
        var queryNames = [String]()
        var updateNames = [String]()
        for member in declaration.memberBlock.members {
            // We need to collect all message handlers
            guard let functionDecl = member.decl.as(FunctionDeclSyntax.self) else {
                continue
            }

            if functionDecl.attributes.contains(where: { element in
                element.as(AttributeSyntax.self)?.attributeName.as(IdentifierTypeSyntax.self)?.description == "WorkflowSignal"
            }) {
                signalNames.append(functionDecl.name.text)
            }

            if functionDecl.attributes.contains(where: { element in
                element.as(AttributeSyntax.self)?.attributeName.as(IdentifierTypeSyntax.self)?.description == "WorkflowQuery"
            }) {
                queryNames.append(functionDecl.name.text)
            }

            if functionDecl.attributes.contains(where: { element in
                element.as(AttributeSyntax.self)?.attributeName.as(IdentifierTypeSyntax.self)?.description == "WorkflowUpdate"
            }) {
                updateNames.append(functionDecl.name.text)
            }
        }

        let rawAccessModifier = declaration.modifiers.accessModifierPrefix(supportedModifiers: .workflowDefinitionAccessModifiers)

        var messageHandlerDecls = [DeclSyntax]()
        if !signalNames.isEmpty {
            messageHandlerDecls.append(
                """
                \(raw: rawAccessModifier)static var signals: [any WorkflowSignalDefinition<\(raw: classDecl.name.text)>] {
                    [\(raw: signalNames.lazy.map { "Self.\($0)" }.joined(separator: ", "))]
                }
                """
            )
        }
        if !queryNames.isEmpty {
            messageHandlerDecls.append(
                """
                \(raw: rawAccessModifier)static var queries: [any WorkflowQueryDefinition<\(raw: classDecl.name.text)>] {
                    [\(raw: queryNames.lazy.map { "Self.\($0)" }.joined(separator: ", "))]
                }
                """
            )
        }
        if !updateNames.isEmpty {
            messageHandlerDecls.append(
                """
                \(raw: rawAccessModifier)static var updates: [any WorkflowUpdateDefinition<\(raw: classDecl.name.text)>] {
                    [\(raw: updateNames.lazy.map { "Self.\($0)" }.joined(separator: ", "))]
                }
                """
            )
        }

        var emptyInitDecl: DeclSyntax?

        // Check if an initializer with a single "input:" parameter (from `WorkflowDefinition` protocol) is already provided
        let hasMatchingInitializer = declaration.memberBlock.members.contains {
            guard let initDecl = $0.decl.as(InitializerDeclSyntax.self) else { return false }

            let matchingInit =
                initDecl.signature.parameterClause.parameters.contains {
                    $0.firstName.text == "input"
                } && initDecl.signature.parameterClause.parameters.count == 1

            if !matchingInit {
                context.diagnose(Diagnostic(node: Syntax(node), message: UnexpectedInitWarning()))
            }

            return matchingInit
        }

        if !hasMatchingInitializer {
            emptyInitDecl = DeclSyntax(
                stringLiteral: """
                    \(rawAccessModifier)required init(input: Input) {}
                    """
            )
        }

        return messageHandlerDecls + (emptyInitDecl.map { [$0] } ?? [])
    }

    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingAttributesFor member: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [AttributeSyntax] {
        guard let property = member.as(VariableDeclSyntax.self), property.isValidForWorkflowState,
            property.identifier != nil
        else {
            return []
        }

        // dont apply to properties that already have the macro
        if property.hasMacroApplication(WorkflowStateMacro.stateMacroName) {
            return []
        }

        return [
            AttributeSyntax(
                attributeName: IdentifierTypeSyntax(
                    name: .identifier(WorkflowStateMacro.stateMacroName)
                )
            )
        ]
    }
}
