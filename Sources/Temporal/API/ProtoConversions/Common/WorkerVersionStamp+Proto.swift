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

extension WorkerVersionStamp {
    init(_ rawValue: Api.Common.V1.WorkerVersionStamp) {
        self = .init(
            buildID: rawValue.buildID,
            useVersioning: rawValue.useVersioning
        )
    }
}
