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

// https://docs.swift.org/compiler/documentation/diagnostics/sendable-metatypes/
// TODO: Remove when we are 6.2 only
#if compiler(>=6.2)
public protocol _SendableMetaTypeBaseProtocol: SendableMetatype {}
#else
public protocol _SendableMetaTypeBaseProtocol {}
#endif
