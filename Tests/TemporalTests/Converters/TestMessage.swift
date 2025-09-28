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

import Foundation
import SwiftProtobuf

struct TestMessage: Message, _MessageImplementationBase, _ProtoNameProviding, Sendable {
    var seconds: Int64 = 0

    var unknownFields = UnknownStorage()

    init() {}

    static let protoMessageName: String = "TestMessage"
    static let _protobuf_nameMap = _NameMap(bytecode: "\0\u{1}seconds\0")

    mutating func decodeMessage<D: Decoder>(decoder: inout D) throws {
        while let fieldNumber = try decoder.nextFieldNumber() {
            switch fieldNumber {
            case 1: try { try decoder.decodeSingularInt64Field(value: &self.seconds) }()
            default: break
            }
        }
    }

    func traverse<V: Visitor>(visitor: inout V) throws {
        if self.seconds != 0 {
            try visitor.visitSingularInt64Field(value: self.seconds, fieldNumber: 1)
        }
        try unknownFields.traverse(visitor: &visitor)
    }

    static func == (lhs: TestMessage, rhs: TestMessage) -> Bool {
        if lhs.seconds != rhs.seconds { return false }
        if lhs.unknownFields != rhs.unknownFields { return false }
        return true
    }
}
