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
import SwiftSyntaxMacros

public struct ActivityMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let functionDecl = declaration.as(FunctionDeclSyntax.self) else {
            throw MacroError(message: "Activity macro can only be applied to member functions")
        }

        guard let enclosingContext = context.lexicalContext.first,
            enclosingContext.is(StructDeclSyntax.self) || enclosingContext.is(ClassDeclSyntax.self)
        else {
            throw MacroError(message: "Activity method must be embedded directly within a struct or class")
        }

        guard functionDecl.genericParameterClause == nil else {
            throw MacroError(message: "Activity macro can not be applied to generic member function")
        }

        let parameters = functionDecl.signature.parameterClause.parameters
        guard parameters.count < 2 else {
            throw MacroError(message: "Activity macro can not be applied to a member function with multiple parameters")
        }

        return []
    }
}
