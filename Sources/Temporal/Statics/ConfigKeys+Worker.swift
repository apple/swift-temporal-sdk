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

    /// The optional Temporal Cloud API key of the ``TemporalWorker``.
    static let workerClientAPIKey: ConfigKey = ["worker", "client", "apiKey"]

    /// The optional worker heartbeat interval in milliseconds of the ``TemporalWorker``.
    static let workerHeartbeatIntervalMs: ConfigKey = ["worker", "heartbeatintervalms"]

    // MARK: - Tuner

    /// The optional slot supplier type for workflow tasks (`"fixed"` or `"resource-based"`).
    static let workerTunerWorkflowType: ConfigKey = ["worker", "tuner", "workflow", "type"]
    /// The optional maximum slots for fixed-size workflow task supplier.
    static let workerTunerWorkflowMaxSlots: ConfigKey = ["worker", "tuner", "workflow", "maxslots"]

    /// The optional slot supplier type for activity tasks (`"fixed"` or `"resource-based"`).
    static let workerTunerActivityType: ConfigKey = ["worker", "tuner", "activity", "type"]
    /// The optional maximum slots for fixed-size activity task supplier.
    static let workerTunerActivityMaxSlots: ConfigKey = ["worker", "tuner", "activity", "maxslots"]

    /// The optional slot supplier type for local activity tasks (`"fixed"` or `"resource-based"`).
    static let workerTunerLocalActivityType: ConfigKey = ["worker", "tuner", "localactivity", "type"]
    /// The optional maximum slots for fixed-size local activity task supplier.
    static let workerTunerLocalActivityMaxSlots: ConfigKey = ["worker", "tuner", "localactivity", "maxslots"]

    /// The optional target memory usage for resource-based slot suppliers (0.0--1.0).
    static let workerTunerTargetMemoryUsage: ConfigKey = ["worker", "tuner", "targetmemoryusage"]
    /// The optional target CPU usage for resource-based slot suppliers (0.0--1.0).
    static let workerTunerTargetCpuUsage: ConfigKey = ["worker", "tuner", "targetcpuusage"]
}
