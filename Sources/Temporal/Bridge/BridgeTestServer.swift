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

package struct BridgeTestServer: ~Copyable, Sendable {
    package struct TestServerOptions: Hashable, Sendable {
        /// The existing path of the downloaded test server.
        var existingPath: String
        /// The SDK name such as `swift-temporal-sdk`.
        var sdkName: String
        /// The SDK version.
        var sdkVersion: String
        /// The version of the test server to download.
        ///
        /// Important this must be set. Use `default` for the latest.
        var downloadVersion: String
        /// The directory where the test server is downloaded to.
        var downloadDestinationDirectory: String
        /// The port to bind the server to.
        ///
        /// Use `0` for random port selection.
        var port: UInt16
        /// Extra arguments passed to the server.
        package var extraArguments: String
        /// Download TTL.
        ///
        /// `0` means no TTL.
        var downloadTtl: Duration

        package static let `default` = TestServerOptions(
            existingPath: "",
            sdkName: "swift-temporal-sdk",
            sdkVersion: "0.0.1",
            downloadVersion: "default",
            downloadDestinationDirectory: "",
            port: 0,
            extraArguments: "",
            downloadTtl: .zero
        )

        package init(
            existingPath: String,
            sdkName: String,
            sdkVersion: String,
            downloadVersion: String,
            downloadDestinationDirectory: String,
            port: UInt16,
            extraArguments: String,
            downloadTtl: Duration
        ) {
            self.existingPath = existingPath
            self.sdkName = sdkName
            self.sdkVersion = sdkVersion
            self.downloadVersion = downloadVersion
            self.downloadDestinationDirectory = downloadDestinationDirectory
            self.port = port
            self.extraArguments = extraArguments
            self.downloadTtl = downloadTtl
        }

        func withBridgeTestServerOptions<Result>(
            _ body: (TemporalCoreTestServerOptions) -> Result
        ) -> Result {
            self.existingPath.withByteArrayRef { existingPathRef in
                self.sdkName.withByteArrayRef { sdkNameRef in
                    self.sdkVersion.withByteArrayRef { sdkVersionRef in
                        self.downloadVersion.withByteArrayRef { downloadVersionRef in
                            self.downloadDestinationDirectory.withByteArrayRef { downloadDestinationDirectoryRef in
                                self.extraArguments.withByteArrayRef { extraArgumentsRef in
                                    return body(
                                        .init(
                                            existing_path: existingPathRef,
                                            sdk_name: sdkNameRef,
                                            sdk_version: sdkVersionRef,
                                            download_version: downloadVersionRef,
                                            download_dest_dir: downloadDestinationDirectoryRef,
                                            port: self.port,
                                            extra_args: extraArgumentsRef,
                                            download_ttl_seconds: UInt64(self.downloadTtl.components.seconds)
                                        )
                                    )
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    package struct DevServerOptions: Hashable, Sendable {
        /// The test server options.
        package var testServerOptions: TestServerOptions
        /// The namespace to create.
        ///
        /// This must be set e.g. `default`.
        var namespace: String
        /// The IP of the server.
        ///
        /// This must be set e.g. `127.0.0.1`.
        var ip: String
        /// The database file to use.
        var databaseFileName: String
        /// If the UI should be enabled.
        var ui: Bool
        /// The port of the UI.
        var uiPort: UInt16
        /// The log format.
        ///
        /// This must be set e.g. `pretty`.
        var logFormat: String
        /// The log level.
        ///
        /// This must be set e.g. `warn`.
        var logLevel: String

        package static let `default` = DevServerOptions(
            testServerOptions: .default,
            namespace: "default",
            ip: "127.0.0.1",
            databaseFileName: "",
            ui: false,
            uiPort: 0,
            logFormat: "pretty",
            logLevel: "warn"
        )

        package init(
            testServerOptions: TestServerOptions,
            namespace: String,
            ip: String,
            databaseFileName: String,
            ui: Bool,
            uiPort: UInt16,
            logFormat: String,
            logLevel: String
        ) {
            self.testServerOptions = testServerOptions
            self.namespace = namespace
            self.ip = ip
            self.databaseFileName = databaseFileName
            self.ui = ui
            self.uiPort = uiPort
            self.logFormat = logFormat
            self.logLevel = logLevel
        }

        func withBridgeDevServerOptions<Result>(
            _ body: (TemporalCoreDevServerOptions) -> Result
        ) -> Result {
            self.namespace.withByteArrayRef { namespaceRef in
                self.ip.withByteArrayRef { ipRef in
                    self.databaseFileName.withByteArrayRef { databaseFileNameRef in
                        self.logFormat.withByteArrayRef { logFormatRef in
                            self.logLevel.withByteArrayRef { logLevelRef in
                                self.testServerOptions.withBridgeTestServerOptions { testServerOptions in
                                    withUnsafePointer(to: testServerOptions) { testServerOptionsPointer in
                                        body(
                                            .init(
                                                test_server: testServerOptionsPointer,
                                                namespace_: namespaceRef,
                                                ip: ipRef,
                                                database_filename: databaseFileNameRef,
                                                ui: self.ui,
                                                ui_port: self.uiPort,
                                                log_format: logFormatRef,
                                                log_level: logLevelRef
                                            )
                                        )
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // only use one runtime for all test servers
    package static let bridgeRuntime = try! BridgeRuntime()
    private nonisolated(unsafe) let serverPointer: OpaquePointer

    package static func withBridgeTestServer<Result: Sendable>(
        testServerOptions: BridgeTestServer.TestServerOptions = .default,
        isolation: isolated (any Actor)? = #isolation,
        _ body: (borrowing BridgeTestServer, String) async throws -> Result
    ) async throws -> Result {
        let (serverPointer, connectTarget): (UnsafeTransfer<OpaquePointer>, String) = try await withCheckedThrowingContinuation { continuation in
            testServerOptions.withBridgeTestServerOptions { testServerOptions in
                withUnsafePointer(to: testServerOptions) { testServerOptionsPointer in
                    let continuationHolder = ContinuationHolder(continuation)
                    let opaqueContinuationHolder = Unmanaged.passRetained(continuationHolder).toOpaque()
                    temporal_core_ephemeral_server_start_test_server(
                        Self.bridgeRuntime.runtime,
                        testServerOptionsPointer,
                        opaqueContinuationHolder
                    ) { userData, success, successTarget, fail in
                        let continuation = Unmanaged<ContinuationHolder<(UnsafeTransfer<OpaquePointer>, String)>>
                            .fromOpaque(userData!).takeRetainedValue().continuation
                        if let fail {
                            continuation.resume(throwing: BridgeError(messagePointer: fail))
                        } else if let success, let successTarget {
                            continuation.resume(
                                returning: (
                                    .init(wrapped: success),
                                    String(byteArray: successTarget.pointee)
                                )
                            )
                        } else {
                            fatalError("Temporal Core SDK bug: No success or fail")
                        }
                    }
                }
            }
        }

        let bridgeTestServer = BridgeTestServer(
            serverPointer: serverPointer.wrapped
        )

        let result: Result
        do {
            result = try await body(bridgeTestServer, connectTarget)
        } catch {
            try await bridgeTestServer.shutdown()
            throw error
        }
        try await bridgeTestServer.shutdown()
        return result
    }

    package static func withBridgeDevServer<Result: Sendable>(
        devServerOptions: BridgeTestServer.DevServerOptions = .default,
        isolation: isolated (any Actor)? = #isolation,
        _ body: (borrowing BridgeTestServer, String) async throws -> sending Result
    ) async throws -> sending Result {
        let (serverPointer, connectTarget): (UnsafeTransfer<OpaquePointer>, String) = try await withCheckedThrowingContinuation { continuation in
            devServerOptions.withBridgeDevServerOptions { devServerOptions in
                withUnsafePointer(to: devServerOptions) { devServerOptionsPointer in
                    let continuationHolder = ContinuationHolder(continuation)
                    let opaqueContinuationHolder = Unmanaged.passRetained(continuationHolder).toOpaque()
                    temporal_core_ephemeral_server_start_dev_server(
                        Self.bridgeRuntime.runtime,
                        devServerOptionsPointer,
                        opaqueContinuationHolder
                    ) { userData, success, successTarget, fail in
                        let continuation = Unmanaged<ContinuationHolder<(UnsafeTransfer<OpaquePointer>, String)>>
                            .fromOpaque(userData!).takeRetainedValue().continuation
                        if let fail {
                            continuation.resume(throwing: BridgeError(messagePointer: fail))
                        } else if let success, let successTarget {
                            continuation.resume(
                                returning: (
                                    .init(wrapped: success),
                                    String(byteArray: successTarget.pointee)
                                )
                            )
                        } else {
                            fatalError("Temporal Core SDK bug: No success or fail")
                        }
                    }
                }
            }
        }

        let bridgeTestServer = BridgeTestServer(
            serverPointer: serverPointer.wrapped
        )

        let result: Result
        do {
            result = try await body(bridgeTestServer, connectTarget)
        } catch {
            try await bridgeTestServer.shutdown()
            throw error
        }
        try await bridgeTestServer.shutdown()
        return result
    }

    private func shutdown() async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, any Error>) in
            let continuationHolder = ContinuationHolder(continuation)
            let opaqueContinuationHolder = Unmanaged.passRetained(continuationHolder).toOpaque()

            temporal_core_ephemeral_server_shutdown(
                self.serverPointer,
                opaqueContinuationHolder
            ) { userData, fail in
                let continuation = Unmanaged<ContinuationHolder<Void>>
                    .fromOpaque(userData!).takeRetainedValue().continuation
                if let fail {
                    continuation.resume(throwing: BridgeError(messagePointer: fail))
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }

    deinit {
        temporal_core_ephemeral_server_free(self.serverPointer)
    }
}
