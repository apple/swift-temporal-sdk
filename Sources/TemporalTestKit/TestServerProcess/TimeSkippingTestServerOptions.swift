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

#if canImport(Subprocess)
/// Configuration for downloading and launching the time-skipping `temporal-test-server` binary.
package struct TimeSkippingTestServerOptions: Hashable, Sendable {
    /// An existing path to a `temporal-test-server` binary to use instead of downloading one.
    package var existingPath: String
    /// The SDK name reported to the download resolution service, e.g. `swift-temporal-sdk`.
    package var sdkName: String
    /// The SDK version reported to the download resolution service.
    package var sdkVersion: String
    /// The version of the test server to download. Use `default` for the SDK-pinned version.
    package var downloadVersion: String
    /// The directory the test server binary is cached in. Empty means the system temp directory.
    package var downloadDestinationDirectory: String
    /// Extra arguments passed to the spawned test server process.
    package var extraArguments: [String]
    /// How long a cached download is considered valid. `nil` means it never expires.
    package var downloadTtl: Duration?

    package init(
        existingPath: String,
        sdkName: String,
        sdkVersion: String,
        downloadVersion: String,
        downloadDestinationDirectory: String,
        extraArguments: [String],
        downloadTtl: Duration?
    ) {
        self.existingPath = existingPath
        self.sdkName = sdkName
        self.sdkVersion = sdkVersion
        self.downloadVersion = downloadVersion
        self.downloadDestinationDirectory = downloadDestinationDirectory
        self.extraArguments = extraArguments
        self.downloadTtl = downloadTtl
    }

    package static let `default` = TimeSkippingTestServerOptions(
        existingPath: "",
        sdkName: "swift-temporal-sdk",
        sdkVersion: "0.0.1",
        downloadVersion: "default",
        downloadDestinationDirectory: "",
        extraArguments: [],
        downloadTtl: .seconds(15 * 24 * 60 * 60)
    )
}
#endif
