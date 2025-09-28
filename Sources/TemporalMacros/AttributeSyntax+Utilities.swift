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

import SwiftSyntax

extension AttributeSyntax {
    func stringLiteralValueForArgument(named name: String) -> StringLiteralExprSyntax? {
        guard case let .argumentList(arguments) = arguments else { return nil }
        guard let firstElement = arguments.first(where: { $0.label?.text == name }) else { return nil }
        guard let stringLiteral = firstElement.expression.as(StringLiteralExprSyntax.self) else { return nil }
        return stringLiteral
    }
    func stringValueForArgument(named name: String) -> String? {
        guard let stringLiteral = stringLiteralValueForArgument(named: name) else { return nil }
        guard stringLiteral.segments.count == 1 else { return nil }
        guard case let .stringSegment(value) = stringLiteral.segments.first else { return nil }
        return value.trimmed.content.text
    }
}
