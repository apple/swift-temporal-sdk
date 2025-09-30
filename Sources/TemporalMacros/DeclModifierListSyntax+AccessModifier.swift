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

extension DeclModifierListSyntax {
    func accessModifierPrefix(supportedModifiers: Set<Keyword>) -> String {
        let modifier = compactMap { (modifier: DeclModifierSyntax) -> TokenSyntax? in
            guard case let .keyword(keyword) = modifier.name.tokenKind else {
                return nil
            }

            guard supportedModifiers.contains(keyword) else {
                return nil
            }
            return .keyword(keyword)
        }.first

        return modifier.map { $0.text + " " } ?? ""
    }
}

extension Set where Element == Keyword {
    static let allAccessModifiers: Set<Keyword> = [
        .public,
        .private,
        .package,
        .internal,
        .fileprivate,
    ]

    static let workflowDefinitionAccessModifiers: Set<Keyword> = {
        var modifiers = Self.allAccessModifiers
        modifiers.remove(.private)
        return modifiers
    }()
}
