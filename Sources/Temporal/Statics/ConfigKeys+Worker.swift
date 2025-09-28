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

import Configuration

extension ConfigKey {
    /// The required namespace of the ``TemporalWorker``.
    static let workerNamespace: ConfigKey = ["worker", "namespace"]
    /// The required task queue of the ``TemporalWorker``.
    static let workerTaskQueue: ConfigKey = ["worker", "taskqueue"]
    /// The required build ID of the ``TemporalWorker``.
    static let workerBuildId: ConfigKey = ["worker", "buildid"]

    /// The required server hostname for instrumentation of the worker client.
    static let workerClientServerHostname: ConfigKey = ["worker", "client", "instrumentation", "serverhostname"]
    /// The optional identity of the client of the ``TemporalWorker``.
    ///
    /// If not provided, a default will be used.
    static let workerClientIdentity: ConfigKey = ["worker", "client", "identity"]
}
