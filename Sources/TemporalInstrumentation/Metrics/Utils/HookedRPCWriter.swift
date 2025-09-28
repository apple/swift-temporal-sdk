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
        try await self.writer.write(contentsOf: elements)
        self.afterEachWrite()
    }
}
