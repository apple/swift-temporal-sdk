//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Temporal SDK open source project
//
// Copyright (c) 2026 Apple Inc. and the Swift Temporal SDK project authors
// Licensed under MIT License
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Swift Temporal SDK project authors
//
// SPDX-License-Identifier: MIT
//
//===----------------------------------------------------------------------===//

// Swift reserved keywords that need to be escaped with backticks
private let swiftReservedKeywords: Set<String> = [
    // Declaration keywords
    "associatedtype", "class", "deinit", "enum", "extension", "fileprivate", "func", "import", "init",
    "inout", "internal", "let", "open", "operator", "private", "precedencegroup", "protocol", "public",
    "rethrows", "static", "struct", "subscript", "typealias", "var",

    // Statement keywords
    "break", "case", "catch", "continue", "default", "defer", "do", "else", "fallthrough", "for",
    "guard", "if", "in", "repeat", "return", "throw", "switch", "where", "while",

    // Expression and type keywords
    "Any", "as", "await", "catch", "false", "is", "nil", "self", "Self", "super", "throw", "throws",
    "true", "try",

    // Pattern keywords
    "_",

    // Keywords reserved in particular contexts
    "Protocol", "Type", "associativity", "convenience", "didSet", "dynamic", "final", "get", "indirect",
    "infix", "lazy", "left", "mutating", "none", "nonmutating", "optional", "override", "postfix",
    "precedence", "prefix", "required", "right", "set", "some", "unowned", "weak", "willSet",
]

private func escapeIfNeeded(_ name: String) -> String {
    if swiftReservedKeywords.contains(name) {
        return "`\(name)`"
    }
    return name
}

enum AccessLevel: String {
    case `public`
    case `package`
    case `fileprivate`
}

enum DeclKind: String {
    case `struct`
    case `enum`
    case `class`
    case `actor`
}

struct TypeInfo {
    let oldName: String
    let namespace: [String]
    let shortName: String
    let accessLevel: AccessLevel
    let declarationKind: DeclKind
    let filePath: String

    var namespacedName: String {
        return (namespace + [shortName]).map { escapeIfNeeded($0) }.joined(separator: ".")
    }

    var namespaceString: String {
        return namespace.map { escapeIfNeeded($0) }.joined(separator: ".")
    }
}
