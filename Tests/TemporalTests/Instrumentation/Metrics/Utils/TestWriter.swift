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

struct TestWriter<WriterElement: Sendable>: RPCWriterProtocol {
    typealias Element = WriterElement

    private let streamContinuation: AsyncStream<Element>.Continuation

    init(streamContinuation: AsyncStream<Element>.Continuation) {
        self.streamContinuation = streamContinuation
    }

    func write(_ element: WriterElement) {
        self.streamContinuation.yield(element)
    }

    func write(contentsOf elements: some Sequence<Self.Element>) {
        // swift-format-ignore: ReplaceForEachWithForLoop
        elements.forEach { element in
            self.write(element)
        }
    }
}
