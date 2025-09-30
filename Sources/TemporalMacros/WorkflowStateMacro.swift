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
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct WorkflowStateMacro: AccessorMacro, PeerMacro {
    static let stateMacroName = "_WorkflowState"

    static var stateAttribute: AttributeSyntax {
        AttributeSyntax(
            leadingTrivia: .space,
            atSign: .atSignToken(),
            attributeName: IdentifierTypeSyntax(
                name: .identifier(stateMacroName)
            ),
            trailingTrivia: .space
        )
    }

    public static func expansion(
        of node: AttributeSyntax,
        providingAccessorsOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [AccessorDeclSyntax] {
        guard let property = declaration.as(VariableDeclSyntax.self),
            property.isValidForWorkflowState,
            let identifier = property.identifier?.trimmed
        else {
            return []
        }

        guard context.lexicalContext[0].as(ClassDeclSyntax.self) != nil else {
            return []
        }

        let initAccessor: AccessorDeclSyntax =
            """
            @storageRestrictions(initializes: _\(identifier))
            init(initialValue) {
                _\(identifier) = .init(initialValue: initialValue)
            }
            """
        let getAccessor: AccessorDeclSyntax =
            """
            get {
                return _\(identifier).value
            }
            """

        // the guard else case must include the assignment else
        // cases that would notify then drop the side effects of `didSet` etc
        let setAccessor: AccessorDeclSyntax =
            """
            set {
                _\(identifier).value = newValue
            }
            """

        return [initAccessor, getAccessor, setAccessor]
    }

    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let property = declaration.as(VariableDeclSyntax.self),
            property.isValidForWorkflowState,
            property.identifier?.trimmed != nil
        else {
            return []
        }

        guard context.lexicalContext[0].as(ClassDeclSyntax.self) != nil else {
            return []
        }

        let storage = DeclSyntax(
            property.privatePrefixed(
                "_",
                removingAttribute: stateAttribute,
                context: context
            )
        )
        return [storage]
    }
}

extension VariableDeclSyntax {
    func privatePrefixed(
        _ prefix: String,
        removingAttribute toRemove: AttributeSyntax,
        context: some MacroExpansionContext
    ) -> VariableDeclSyntax {
        let newAttributes = attributes.filter { (attribute: AttributeListSyntax.Element) -> Bool in
            switch attribute {
            case .attribute(let attr):
                attr.attributeName.identifier != toRemove.attributeName.identifier
            default: true
            }
        }
        return VariableDeclSyntax(
            leadingTrivia: leadingTrivia,
            attributes: newAttributes,
            modifiers: modifiers.privatePrefixed(prefix),
            bindingSpecifier: TokenSyntax(bindingSpecifier.tokenKind, leadingTrivia: .space, trailingTrivia: .space, presence: .present),
            bindings: bindings.privatePrefixed(prefix, context: context),
            trailingTrivia: trailingTrivia
        )
    }

    var isValidForWorkflowState: Bool {
        !isComputed && isInstance && !isImmutable && identifier != nil
    }

    var isComputed: Bool {
        guard accessorsMatching({ $0 == .keyword(.get) }).count > 0 else {
            return bindings.contains { binding in
                guard case .getter = binding.accessorBlock?.accessors else {
                    return false
                }
                return true
            }
        }
        return true
    }

    var isImmutable: Bool {
        return bindingSpecifier.tokenKind == .keyword(.let)
    }

    var isInstance: Bool {
        for modifier in modifiers {
            for token in modifier.tokens(viewMode: .all) {
                if token.tokenKind == .keyword(.static) || token.tokenKind == .keyword(.class) {
                    return false
                }
            }
        }
        return true
    }

    var identifier: TokenSyntax? {
        identifierPattern?.identifier
    }

    func accessorsMatching(_ predicate: (TokenKind) -> Bool) -> [AccessorDeclSyntax] {
        let accessors: [AccessorDeclListSyntax.Element] = bindings.compactMap { patternBinding in
            switch patternBinding.accessorBlock?.accessors {
            case .accessors(let accessors):
                return accessors
            default:
                return nil
            }
        }.flatMap { $0 }
        return accessors.compactMap { accessor in
            guard predicate(accessor.accessorSpecifier.tokenKind) else {
                return nil
            }
            return accessor
        }
    }

    var identifierPattern: IdentifierPatternSyntax? {
        bindings.first?.pattern.as(IdentifierPatternSyntax.self)
    }

    func hasMacroApplication(_ name: String) -> Bool {
        for attribute in attributes {
            switch attribute {
            case .attribute(let attr):
                if attr.attributeName.tokens(viewMode: .all).map({ $0.tokenKind }) == [.identifier(name)] {
                    return true
                }
            default:
                break
            }
        }
        return false
    }
}

extension DeclModifierListSyntax {
    func privatePrefixed(_ prefix: String) -> DeclModifierListSyntax {
        let privateModifier: DeclModifierSyntax = DeclModifierSyntax(name: "private", trailingTrivia: .space)
        let nonisolatedModifier: DeclModifierSyntax = DeclModifierSyntax(
            name: "nonisolated",
            detail: .init(
                leftParen: .leftParenToken(),
                detail: "unsafe",
                rightParen: .rightParenToken()
            )
        )
        return [privateModifier, nonisolatedModifier]
            + filter {
                switch $0.name.tokenKind {
                case .keyword(let keyword):
                    switch keyword {
                    case .fileprivate, .private, .internal, .package, .public:
                        return false
                    default:
                        return true
                    }
                default:
                    return true
                }
            }
    }
}

extension TokenSyntax {
    func privatePrefixed(
        _ prefix: String
    ) -> TokenSyntax {
        switch tokenKind {
        case .identifier(let identifier):
            return TokenSyntax(.identifier(prefix + identifier), leadingTrivia: leadingTrivia, trailingTrivia: trailingTrivia, presence: presence)
        default:
            return self
        }
    }
}

extension PatternBindingListSyntax {
    func privatePrefixed(
        _ prefix: String,
        context: some MacroExpansionContext
    ) -> PatternBindingListSyntax {
        var bindings = self.map { $0 }
        for index in 0..<bindings.count {
            let binding = bindings[index]
            let stateTypeAnnotation: TypeAnnotationSyntax?
            if var typeAnnotation = binding.typeAnnotation {
                typeAnnotation.type = .init(
                    stringLiteral: "_WorkflowState<\(typeAnnotation.type.description)>"
                )
                stateTypeAnnotation = typeAnnotation
            } else {
                stateTypeAnnotation = nil
            }
            let stateInitializer: InitializerClauseSyntax?
            if var initializer = binding.initializer {
                initializer.value = .init(
                    stringLiteral: "_WorkflowState(initialValue: \(initializer.value.description))"
                )
                stateInitializer = initializer
            } else if binding.typeAnnotation?.type.is(OptionalTypeSyntax.self) ?? false {
                stateInitializer = InitializerClauseSyntax(
                    value: FunctionCallExprSyntax(
                        calledExpression: DeclReferenceExprSyntax(
                            baseName: "_WorkflowState",
                        ),
                        leftParen: .leftParenToken(),
                        arguments: LabeledExprListSyntax(
                            arrayLiteral: LabeledExprSyntax(label: "initialValue", expression: NilLiteralExprSyntax())
                        ),
                        rightParen: .rightParenToken()
                    )
                )
            } else {
                stateInitializer = nil
            }
            if let identifier = binding.pattern.as(IdentifierPatternSyntax.self) {
                bindings[index] = PatternBindingSyntax(
                    leadingTrivia: binding.leadingTrivia,
                    pattern: IdentifierPatternSyntax(
                        leadingTrivia: identifier.leadingTrivia,
                        identifier: identifier.identifier.privatePrefixed(prefix)
                    ),
                    typeAnnotation: stateTypeAnnotation,
                    initializer: stateInitializer,
                    accessorBlock: binding.accessorBlock?.locationAnnotated(context: context),
                    trailingComma: binding.trailingComma,
                    trailingTrivia: binding.trailingTrivia
                )

            }
        }

        return PatternBindingListSyntax(bindings)
    }
}

extension AccessorBlockSyntax {
    func locationAnnotated(context: some MacroExpansionContext) -> AccessorBlockSyntax {
        switch accessors {
        case .accessors(let accessorList):
            let remapped = AccessorDeclListSyntax {
                accessorList.map { $0.locationAnnotated(context: context) }
            }
            return AccessorBlockSyntax(accessors: .accessors(remapped))
        case .getter(let codeBlockList):
            return AccessorBlockSyntax(accessors: .getter(codeBlockList))
        }
    }
}

extension AccessorDeclSyntax {
    func locationAnnotated(context: some MacroExpansionContext) -> AccessorDeclSyntax {
        return AccessorDeclSyntax(
            leadingTrivia: leadingTrivia,
            attributes: attributes,
            modifier: modifier,
            accessorSpecifier: accessorSpecifier,
            parameters: parameters,
            effectSpecifiers: effectSpecifiers,
            body: body?.locationAnnotated(context: context),
            trailingTrivia: trailingTrivia
        )
    }
}

extension CodeBlockSyntax {
    func locationAnnotated(context: some MacroExpansionContext) -> CodeBlockSyntax {
        guard let firstStatement = statements.first, let loc = context.location(of: firstStatement) else {
            return self
        }

        return CodeBlockSyntax(
            leadingTrivia: leadingTrivia,
            leftBrace: leftBrace,
            statements: CodeBlockItemListSyntax {
                "#sourceLocation(file: \(loc.file), line: \(loc.line))"
                statements
                "#sourceLocation()"
            },
            rightBrace: rightBrace,
            trailingTrivia: trailingTrivia
        )
    }
}

extension TypeSyntax {
    var identifier: String? {
        for token in tokens(viewMode: .all) {
            switch token.tokenKind {
            case .identifier(let identifier):
                return identifier
            default:
                break
            }
        }
        return nil
    }
}
