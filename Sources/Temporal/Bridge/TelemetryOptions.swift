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

/// Telemetry options for the worker.
// TODO: Check if we can make this non-public
public struct TelemetryOptions: Hashable, Sendable {
    public struct Logging: Hashable, Sendable {
        public struct Filter: Hashable, Sendable {
            /// Level for Temporal Core SDK log messages.
            public var core: Logger.Level

            /// Level for other Rust log messages.
            public var other: Logger.Level

            /// Creates new logging filter options.
            ///
            /// - Parameters:
            ///   - core: Level for Temporal Core SDK log messages. Defaults to `warning`.
            ///   - other: Level for other Rust log messages. Defaults to `error`.
            public init(
                core: Logger.Level = .warning,
                other: Logger.Level = .error
            ) {
                self.core = core
                self.other = other
            }
        }

        /// The logging filter.
        public var filter: Filter

        /// Creates new logging options.
        ///
        /// - Parameter filter: The logging filter. Defaults to the default filter.
        public init(filter: Filter = .init()) {
            self.filter = filter
        }
    }

    /// The logging options.
    ///
    /// `nil` disables logging.
    public var logging: Logging?

    /// Creates new telemetry options.
    ///
    /// - Parameter logging: The logging options. Defaults to the default logging options.
    public init(logging: Logging? = .init()) {
        self.logging = logging
    }

    /// Invokes the given closure with a correlating `Bridge.TelemetryOptions`.
    ///
    /// - Parameter body: The closure to run with the created options.
    /// - Returns: The result of the closure.
    func withBridgeOptions<Result>(
        body: (TemporalCoreTelemetryOptions) throws -> Result
    ) throws -> Result {
        guard let logFilter = logging?.filter.temporalFilterString else {
            return try body(Bridge.TemporalCoreTelemetryOptions(logging: nil, metrics: nil))
        }
        return try logFilter.withByteArrayRef { logFilterByteArrayRef in
            let loggingOptions = TemporalCoreLoggingOptions(
                filter: logFilterByteArrayRef,
                forward_to: logCallback
            )
            return try withUnsafePointer(to: loggingOptions) { loggingOptionsPointer in
                let options = TemporalCoreTelemetryOptions(
                    logging: loggingOptionsPointer,
                    metrics: nil
                )
                return try body(options)
            }
        }
    }
}

extension TelemetryOptions.Logging.Filter {
    var temporalFilterString: String {
        let coreLevel = self.core.temporalLevel
        let otherLevel = self.other.temporalLevel
        return "\(otherLevel),temporal_sdk_core=\(coreLevel),temporal_client=\(coreLevel),temporal_sdk=\(coreLevel)"
    }
}

extension Logger.Level {
    fileprivate var temporalLevel: String {
        switch self {
        case .trace:
            "TRACE"
        case .debug:
            "DEBUG"
        case .info, .notice:
            "INFO"
        case .warning:
            "WARN"
        case .critical, .error:
            "ERROR"
        }
    }
}

extension TemporalCoreForwardedLogLevel {
    fileprivate var level: Logger.Level {
        switch self {
        case Bridge.Trace:
            .trace
        case Bridge.Debug:
            .debug
        case Bridge.Info:
            .info
        case Bridge.Warn:
            .warning
        case Bridge.Error:
            .error
        default:
            .critical
        }
    }
}

private let logger = Logger(label: "TemporalBridgeLogger")
private func logCallback(level: TemporalCoreForwardedLogLevel, log: OpaquePointer?) {
    let message = temporal_core_forwarded_log_message(log)
    logger.log(level: level.level, "\(String(byteArrayRef: message))")
}
