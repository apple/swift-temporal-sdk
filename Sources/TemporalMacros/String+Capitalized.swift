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
        guard let firstLetterIndex = firstIndex(where: \.isLetter) else { return self }
        guard self[firstLetterIndex].isLowercase else { return self }
        var result = self
        result.replaceSubrange(
            firstLetterIndex...firstLetterIndex,
            with: self[firstLetterIndex].uppercased()
        )
        return result
    }
}
