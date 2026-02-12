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
import Logging

package final class BridgeRuntime: Sendable {
    nonisolated(unsafe) let runtime: OpaquePointer

    init(
        telemetryOptions: TelemetryOptions = .init(),
        workerHeartbeatInterval: Duration = .zero
    ) throws {
        self.runtime = try telemetryOptions.withBridgeOptions { bridgeTelemetryOptions in
            return try withUnsafePointer(to: bridgeTelemetryOptions) { bridgeTelemetryOptionsPointer in
                var options: TemporalCoreRuntimeOptions = TemporalCoreRuntimeOptions(
                    telemetry: bridgeTelemetryOptionsPointer,
                    worker_heartbeat_interval_millis: workerHeartbeatInterval.milliseconds
                )
                let maybeRuntime = temporal_core_runtime_new(&options)

                if let fail = maybeRuntime.fail {
                    throw BridgeError(messagePointer: fail)
                }

                return maybeRuntime.runtime
            }
        }
    }

    deinit {
        temporal_core_runtime_free(self.runtime)
    }
}
