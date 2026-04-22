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

import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

private struct ActivityInfo {
    var name: String?
    var isDynamic: Bool
    var parentMethodName: String
    var parentTypeName: String
    var accessModifier: DeclModifierListSyntax
    var isStatic: Bool
    var inputType: String
    var resultType: String

    var structDefinition: DeclSyntax {
        let closureType: String = "@Sendable (\(inputType)) async throws -> \(resultType)"

        let nameDecl: String
        if isDynamic {
            nameDecl = "static var isDynamic: Bool { true }"
        } else {
            nameDecl = "static var name: String { \"\(name!)\" }"
        }

        return """
            \(accessModifier)struct \(raw: parentMethodName.capitalizingFirst()): ActivityDefinition {
                \(accessModifier)\(raw: nameDecl)
                var _run: \(raw: closureType)
                init(run: @escaping \(raw: closureType)) { self._run = run }
                \(accessModifier)func run(input: \(raw: inputType == "" ? "Void" : inputType)) async throws -> \(raw: resultType) {
                    return try await self._run(\(raw: inputType == "" ? "" : "input"))
                }
            }
            """
    }

    var varDefinition: DeclSyntax {
        return """
            \(accessModifier)var \(raw: parentMethodName): \(raw: parentMethodName.capitalizingFirst()) {
                return .init(run: \(raw: isStatic ? parentTypeName : "self.container").\(raw: parentMethodName))
            }
            """
    }
}

/// Macro implementation for the `@ActivityContainer` attribute.
public struct ActivityContainerMacro: ExtensionMacro {
    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        guard !(declaration.is(EnumDeclSyntax.self) || declaration.is(ProtocolDeclSyntax.self)) else {
            throw MacroError(message: "ActivityContainer macro can not be applied to enumeration or protocol types.")
        }

        guard !declaration.modifiers.contains(where: { $0.name.tokenKind == .keyword(.private) }) else {
            throw MacroError(message: "ActivityContainer macro can not be applied to private types.")
        }

        var activities: [ActivityInfo] = []

        let declarationAccessModifier = declaration.modifiers.accessModifierPrefix(supportedModifiers: .workflowDefinitionAccessModifiers)

        for member in declaration.memberBlock.members {
            guard let functionDecl = member.decl.as(FunctionDeclSyntax.self),
                let activityAttribute = functionDecl.attributes.first(where: {
                    $0.as(AttributeSyntax.self)?.attributeName.trimmedDescription == "Activity"
                })?.as(AttributeSyntax.self)
            else {
                continue
            }

            let activityAccessModifiers = functionDecl.modifiers.accessModifierPrefix(supportedModifiers: .allAccessModifiers)
            let methodName = functionDecl.name.trimmedDescription
            let isDynamic = activityAttribute.boolValueForArgument(named: "dynamic") ?? false
            let activityName: String?
            if isDynamic {
                activityName = nil
            } else {
                activityName = activityAttribute.stringValueForArgument(named: "name") ?? methodName.capitalizingFirst()
            }

            activities.append(
                ActivityInfo(
                    name: activityName,
                    isDynamic: isDynamic,
                    parentMethodName: methodName,
                    parentTypeName: type.trimmedDescription,
                    accessModifier: activityAccessModifiers,
                    isStatic: functionDecl.modifiers.contains { $0.trimmedDescription == "static" },
                    inputType: functionDecl.signature.parameterClause.parameters.first?.type.trimmedDescription ?? "",
                    resultType: functionDecl.signature.returnClause?.type.trimmedDescription ?? "Void"
                )
            )
        }

        let allStatic = activities.allSatisfy { $0.isStatic }
        let activitiesStruct: StructDeclSyntax = StructDeclSyntax(
            modifiers: declarationAccessModifier,
            name: "Activities"
        ) {
            if !allStatic {
                DeclSyntax("let container: \(type)")
            }

            for activity in activities {
                activity.structDefinition
                activity.varDefinition
            }
        }

        return [
            try .init(
                """
                extension \(type): ActivityContainer {
                    \(activitiesStruct.formatted())
                    \(declarationAccessModifier)var activities: Activities { return .init(\(raw: allStatic ? "" : "container: self")) }
                    \(declarationAccessModifier)var allActivities: [any ActivityDefinition] { return [\(raw: activities.map { "self.activities.\($0.parentMethodName)" }.joined(separator: ", "))] }
                }
                """
            )
        ]
    }
}
