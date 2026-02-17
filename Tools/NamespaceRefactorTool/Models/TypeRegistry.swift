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

final class TypeRegistry {
    private var types: [String: TypeInfo] = [:]
    private var typesSortedByLength: [TypeInfo]?

    func register(_ typeInfo: TypeInfo) {
        types[typeInfo.oldName] = typeInfo
        typesSortedByLength = nil  // Invalidate cache
    }

    func lookup(oldName: String) -> TypeInfo? {
        return types[oldName]
    }

    func allTypes() -> [TypeInfo] {
        return Array(types.values)
    }

    func sortedByLength() -> [TypeInfo] {
        if let cached = typesSortedByLength {
            return cached
        }

        let sorted = Array(types.values).sorted { $0.oldName.count > $1.oldName.count }
        typesSortedByLength = sorted
        return sorted
    }
}
