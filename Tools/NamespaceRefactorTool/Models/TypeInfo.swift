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
        (namespace + [shortName]).map { escapeIfNeeded($0) }.joined(separator: ".")
    }

    var namespaceString: String {
        namespace.map { escapeIfNeeded($0) }.joined(separator: ".")
    }
}
