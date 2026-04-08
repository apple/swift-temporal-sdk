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

    struct ValidatorError: DiagnosticMessage {
        var message: String
        var diagnosticID: MessageID { MessageID(domain: "WorkflowMacro", id: "validator_error") }
        var severity: DiagnosticSeverity { .error }
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
        let accessModifier = declaration.modifiers.accessModifierPrefix(supportedModifiers: .workflowDefinitionAccessModifiers)

        // The first argument to our @Workflow macro is the custom name
        return [
            try .init(
                """
                extension \(type): WorkflowDefinition {
                    \(accessModifier)static var name: String { \(workflowName) }
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

            if let updateAttribute = functionDecl.attributes.first(where: { element in
                element.as(AttributeSyntax.self)?.attributeName.as(IdentifierTypeSyntax.self)?.description == "WorkflowUpdate"
            })?.as(AttributeSyntax.self) {
                updateNames.append(functionDecl.name.text)

                // Validate the referenced validator method if specified
                if let validatorName = updateAttribute.stringValueForArgument(named: "validator") {
                    let allFunctions = declaration.memberBlock.members.compactMap {
                        $0.decl.as(FunctionDeclSyntax.self)
                    }
                    if let validatorFunc = allFunctions.first(where: { $0.name.text == validatorName }) {
                        // Validator must not be async
                        if validatorFunc.signature.effectSpecifiers?.asyncSpecifier?.presence == .present {
                            context.diagnose(
                                Diagnostic(
                                    node: Syntax(validatorFunc),
                                    message: ValidatorError(message: "Validator method '\(validatorName)' must not be async")
                                )
                            )
                        }

                        // Validator must return Void
                        if let returnClause = validatorFunc.signature.returnClause,
                            returnClause.type.as(IdentifierTypeSyntax.self)?.name.text != "Void"
                        {
                            context.diagnose(
                                Diagnostic(
                                    node: Syntax(returnClause),
                                    message: ValidatorError(message: "Validator method '\(validatorName)' must return Void")
                                )
                            )
                        }

                        // Validator must have exactly one parameter called 'input'
                        let validatorParams = validatorFunc.signature.parameterClause.parameters
                        if validatorParams.count != 1 {
                            context.diagnose(
                                Diagnostic(
                                    node: Syntax(validatorFunc.signature.parameterClause),
                                    message: ValidatorError(
                                        message: "Validator method '\(validatorName)' must have exactly one parameter matching the update input"
                                    )
                                )
                            )
                        } else if let validatorParam = validatorParams.first {
                            if validatorParam.firstName.text != "input" {
                                context.diagnose(
                                    Diagnostic(
                                        node: Syntax(validatorParam),
                                        message: ValidatorError(
                                            message: "Validator method '\(validatorName)' parameter must be called 'input'"
                                        )
                                    )
                                )
                            }

                            // Check input type matches
                            let updateParams = functionDecl.signature.parameterClause.parameters
                            if let updateParam = updateParams.first {
                                let updateType = updateParam.type.description.trimmingCharacters(in: .whitespaces)
                                let validatorType = validatorParam.type.description.trimmingCharacters(in: .whitespaces)
                                if updateType != validatorType {
                                    context.diagnose(
                                        Diagnostic(
                                            node: Syntax(validatorParam.type),
                                            message: ValidatorError(
                                                message:
                                                    "Validator method '\(validatorName)' input type '\(validatorType)' does not match update input type '\(updateType)'"
                                            )
                                        )
                                    )
                                }
                            }
                        }
                    } else {
                        context.diagnose(
                            Diagnostic(
                                node: Syntax(updateAttribute),
                                message: ValidatorError(message: "Validator method '\(validatorName)' not found in workflow class")
                            )
                        )
                    }
                }
            }
        }

        let accessModifier = declaration.modifiers.accessModifierPrefix(supportedModifiers: .workflowDefinitionAccessModifiers)

        var messageHandlerDecls = [DeclSyntax]()
        if !signalNames.isEmpty {
            messageHandlerDecls.append(
                """
                \(accessModifier)static var signals: [any WorkflowSignalDefinition<\(raw: classDecl.name.text)>] {
                    [\(raw: signalNames.lazy.map { "Self.\($0)" }.joined(separator: ", "))]
                }
                """
            )
        }
        if !queryNames.isEmpty {
            messageHandlerDecls.append(
                """
                \(accessModifier)static var queries: [any WorkflowQueryDefinition<\(raw: classDecl.name.text)>] {
                    [\(raw: queryNames.lazy.map { "Self.\($0)" }.joined(separator: ", "))]
                }
                """
            )
        }
        if !updateNames.isEmpty {
            messageHandlerDecls.append(
                """
                \(accessModifier)static var updates: [any WorkflowUpdateDefinition<\(raw: classDecl.name.text)>] {
                    [\(raw: updateNames.lazy.map { "Self.\($0)" }.joined(separator: ", "))]
                }
                """
            )
        }

        var emptyInitDecl: InitializerDeclSyntax?

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
            emptyInitDecl = InitializerDeclSyntax(
                modifiers: (accessModifier) + [
                    .init(name: .keyword(.required))
                ],
                signature: .init(
                    parameterClause: .init(parameters: [
                        FunctionParameterSyntax(firstName: .identifier("input"), type: IdentifierTypeSyntax(name: .identifier("Input")))
                        // .init(firstName: "input", type: "Input")
                    ])
                ),
                bodyBuilder: {}
            )
        }

        return messageHandlerDecls + (DeclSyntax(emptyInitDecl).map { [$0] } ?? [])
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
