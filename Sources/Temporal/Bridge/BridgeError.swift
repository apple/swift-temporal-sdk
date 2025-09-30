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

import Bridge
import Foundation

struct BridgeError: Error, Hashable {
    let message: String
    let details: String?

    init(message: String, details: String? = nil) {
        self.message = message
        self.details = details
    }

    init(
        messagePointer: consuming UnsafePointer<TemporalCoreByteArray>,
        detailsPointer: consuming UnsafePointer<TemporalCoreByteArray>? = nil
    ) {
        self.message = String(data: Data(byteArrayPointer: messagePointer), encoding: .utf8) ?? "Unknown error"

        if let detailsPointer {
            self.details = String(byteArray: detailsPointer.pointee)
        } else {
            self.details = nil
        }
    }
}
