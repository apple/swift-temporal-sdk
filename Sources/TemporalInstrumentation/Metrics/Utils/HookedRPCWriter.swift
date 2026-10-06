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

import GRPCCore

struct HookedRPCWriter<Writer: RPCWriterProtocol>: RPCWriterProtocol {
    private let writer: Writer
    private let afterEachWrite: @Sendable () -> Void

    init(
        wrapping other: Writer,
        afterEachWrite: @Sendable @escaping () -> Void
    ) {
        self.writer = other
        self.afterEachWrite = afterEachWrite
    }

    func write(_ element: Writer.Element) async throws {
        try await self.writer.write(element)
        self.afterEachWrite()
    }

    func write(contentsOf elements: some Sequence<Writer.Element>) async throws {
        // Written one by one, since `elements` and its conformance to `Sequence` may be isolated to the caller
        for element in elements {
            try await self.write(element)
        }
    }
}
