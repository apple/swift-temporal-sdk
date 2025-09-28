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

//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2023 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for Swift project authors
//

import SwiftDiagnostics
import SwiftOperators
import SwiftParser
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacroExpansion
import SwiftSyntaxMacros
import TemporalMacros

private var allMacros: [String: any Macro.Type] {
    [
        "Workflow": WorkflowMacro.self,
        "WorkflowSignal": WorkflowSignalMacro.self,
        "WorkflowQuery": WorkflowQueryMacro.self,
        "WorkflowUpdate": WorkflowUpdateMacro.self,
        "_WorkflowState": WorkflowStateMacro.self,
        "Activity": ActivityMacro.self,
        "ActivityContainer": ActivityContainerMacro.self,
    ]
}

func parse(
    _ sourceCode: String,
    activeMacros activeMacroNames: [String] = [],
    removeWhitespace: Bool = false
) throws -> (sourceCode: String, diagnostics: [Diagnostic]) {
    let activeMacros: [String: any Macro.Type]
    if activeMacroNames.isEmpty {
        activeMacros = allMacros
    } else {
        activeMacros = allMacros.filter { activeMacroNames.contains($0.key) }
    }
    let operatorTable = OperatorTable.standardOperators
    let originalSyntax = try operatorTable.foldAll(Parser.parse(source: sourceCode))
    let context = BasicMacroExpansionContext(lexicalContext: [], expansionDiscriminator: "", sourceFiles: [:])
    let syntax = try operatorTable.foldAll(
        originalSyntax.expand(macros: activeMacros) { syntax in
            BasicMacroExpansionContext(sharingWith: context, lexicalContext: syntax.allMacroLexicalContexts())
        }
    )
    var sourceCode = String(describing: syntax.formatted().trimmed)
    if removeWhitespace {
        sourceCode = sourceCode.filter { !$0.isWhitespace }
    }
    return (sourceCode, context.diagnostics)
}
