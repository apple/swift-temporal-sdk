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
import Foundation
#if canImport(System)
import System
#else
import SystemPackage
#endif
@testable import TemporalTestKit
import Testing

@Suite
struct TestServerBinaryCacheTests {
    private func makeTemporaryDirectory() throws -> String {
        let directory = NSTemporaryDirectory() + "TestServerBinaryCacheTests-\(UUID().uuidString)"
        try FileManager.default.createDirectory(atPath: directory, withIntermediateDirectories: true)
        return directory
    }

    @Test
    func cachedPathUsesSdkNameAndVersionForDefaultDownloadVersion() throws {
        let directory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(atPath: directory) }

        var options = TimeSkippingTestServerOptions.default
        options.downloadDestinationDirectory = directory
        options.sdkName = "swift-temporal-sdk"
        options.sdkVersion = "1.2.3"
        options.downloadVersion = "default"

        let path = cachedTestServerPath(options: options)
        #expect(path.string == directory + "/temporal-test-server-swift-temporal-sdk-1.2.3")
    }

    @Test
    func cachedPathUsesFixedVersionWhenNotDefault() throws {
        let directory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(atPath: directory) }

        var options = TimeSkippingTestServerOptions.default
        options.downloadDestinationDirectory = directory
        options.downloadVersion = "1.9.0"

        let path = cachedTestServerPath(options: options)
        #expect(path.string == directory + "/temporal-test-server-1.9.0")
    }

    @Test
    func cachedPathDefaultsToSystemTempDirectoryWhenUnset() {
        var options = TimeSkippingTestServerOptions.default
        options.downloadDestinationDirectory = ""

        let path = cachedTestServerPath(options: options)
        #expect(path.string.hasPrefix(NSTemporaryDirectory()))
    }

    @Test
    func missingFileIsNeverValid() throws {
        let directory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(atPath: directory) }

        let missing = FilePath(directory + "/does-not-exist")
        #expect(!isCachedTestServerValid(at: missing, ttl: nil))
        #expect(!isCachedTestServerValid(at: missing, ttl: .seconds(60)))
    }

    @Test
    func existingFileWithNilTtlIsAlwaysValid() throws {
        let directory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(atPath: directory) }

        let path = directory + "/binary"
        FileManager.default.createFile(atPath: path, contents: Data())
        try FileManager.default.setAttributes(
            [.modificationDate: Date.now.addingTimeInterval(-1_000_000)],
            ofItemAtPath: path
        )

        #expect(isCachedTestServerValid(at: FilePath(path), ttl: nil))
    }

    @Test
    func freshFileWithinTtlIsValid() throws {
        let directory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(atPath: directory) }

        let path = directory + "/binary"
        FileManager.default.createFile(atPath: path, contents: Data())

        #expect(isCachedTestServerValid(at: FilePath(path), ttl: .seconds(60)))
        #expect(FileManager.default.fileExists(atPath: path))
    }

    @Test
    func expiredFileIsInvalidAndRemoved() throws {
        let directory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(atPath: directory) }

        let path = directory + "/binary"
        FileManager.default.createFile(atPath: path, contents: Data())
        try FileManager.default.setAttributes(
            [.modificationDate: Date.now.addingTimeInterval(-120)],
            ofItemAtPath: path
        )

        #expect(!isCachedTestServerValid(at: FilePath(path), ttl: .seconds(60)))
        #expect(!FileManager.default.fileExists(atPath: path))
    }

    @Test
    func abandonedLockFileIsClearedAndRetried() async throws {
        let directory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(atPath: directory) }

        let destination = directory + "/binary"
        let lockPath = destination + ".downloading"
        FileManager.default.createFile(atPath: lockPath, contents: Data())
        try FileManager.default.setAttributes(
            [.modificationDate: Date.now.addingTimeInterval(-91)],
            ofItemAtPath: lockPath
        )

        let shouldRetry = try await waitForConcurrentDownload(
            lockPath: FilePath(lockPath),
            destination: FilePath(destination)
        )

        #expect(!shouldRetry)
        #expect(!FileManager.default.fileExists(atPath: lockPath))
    }
}

@Suite
struct TestServerDownloadInfoTests {
    @Test
    func defaultVersionIncludesSdkQueryItems() {
        let url = testServerDownloadURL(downloadVersion: "default", sdkName: "swift-temporal-sdk", sdkVersion: "0.0.1")
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)!

        #expect(components.path == "/temporal-test-server/default")
        let queryItems = Dictionary(uniqueKeysWithValues: (components.queryItems ?? []).map { ($0.name, $0.value) })
        #expect(queryItems["sdk-name"] == "swift-temporal-sdk")
        #expect(queryItems["sdk-version"] == "0.0.1")
        #expect(queryItems["arch"] != nil)
        #expect(queryItems["platform"] != nil)
    }

    @Test
    func fixedVersionOmitsSdkQueryItems() {
        let url = testServerDownloadURL(downloadVersion: "1.9.0", sdkName: "swift-temporal-sdk", sdkVersion: "0.0.1")
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)!

        #expect(components.path == "/temporal-test-server/1.9.0")
        let queryItems = Dictionary(uniqueKeysWithValues: (components.queryItems ?? []).map { ($0.name, $0.value) })
        #expect(queryItems["sdk-name"] == nil)
        #expect(queryItems["sdk-version"] == nil)
    }
}
#endif
