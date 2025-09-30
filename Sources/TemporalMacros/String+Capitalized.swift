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

extension String {
    func capitalizingFirst() -> String {
        let capitalized = capitalized
        guard count > 1 else { return capitalized }

        // The string may already be capitalized.
        let prefix = capitalized.commonPrefix(with: self)
        guard prefix.rangeOfCharacter(from: .letters) == nil else {
            return self
        }

        // There may be backticks at the start / end of string.
        // `capitalized` handles that automatically
        return String(capitalized.prefix(prefix.count + 1) + dropFirst(prefix.count + 1))
    }
}
