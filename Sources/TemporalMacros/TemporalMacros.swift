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

import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct TemporalMacrosPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        WorkflowMacro.self,
        WorkflowSignalMacro.self,
        WorkflowQueryMacro.self,
        WorkflowUpdateMacro.self,
        WorkflowStateMacro.self,
        ActivityMacro.self,
        ActivityContainerMacro.self,
    ]
}
