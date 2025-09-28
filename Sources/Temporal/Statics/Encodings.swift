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

enum Encodings {
    internal static let encodingKey = "encoding"
    internal static let binaryNil = "binary/null"
    internal static let binaryPlain = "binary/plain"
    internal static let jsonProtobuf = "json/protobuf"
    internal static let binaryProtobuf = "binary/protobuf"
    internal static let jsonPlain = "json/plain"
}
