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
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import Subprocess
#if canImport(System)
import System
#else
import SystemPackage
#endif
#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#elseif canImport(Musl)
import Musl
#endif

/// Returns the path to a ready-to-run `temporal-test-server` binary, downloading and
/// caching it first if necessary.
func ensureTestServerDownloaded(options: TimeSkippingTestServerOptions) async throws -> FilePath {
    if !options.existingPath.isEmpty {
        return FilePath(options.existingPath)
    }

    let destination = cachedTestServerPath(options: options)

    if isCachedTestServerValid(at: destination, ttl: options.downloadTtl) {
        return destination
    }

    let maxAttempts = 3
    for _ in 0..<maxAttempts {
        if try await downloadTestServerIfNeeded(to: destination, options: options) {
            return destination
        }
    }
    throw TestServerProcessError.lockTimedOut(path: destination.string)
}

func cachedTestServerPath(options: TimeSkippingTestServerOptions) -> FilePath {
    let destinationDirectory =
        options.downloadDestinationDirectory.isEmpty
        ? FilePath(NSTemporaryDirectory())
        : FilePath(options.downloadDestinationDirectory)
    let filename =
        options.downloadVersion == "default"
        ? "temporal-test-server-\(options.sdkName)-\(options.sdkVersion)"
        : "temporal-test-server-\(options.downloadVersion)"
    return destinationDirectory.appending(filename)
}

func isCachedTestServerValid(at destination: FilePath, ttl: Duration?) -> Bool {
    guard FileManager.default.fileExists(atPath: destination.string) else {
        return false
    }
    guard let ttl else {
        return true
    }
    guard
        let attributes = try? FileManager.default.attributesOfItem(atPath: destination.string),
        let modificationDate = attributes[.modificationDate] as? Date
    else {
        return false
    }
    if Date.now.timeIntervalSince(modificationDate) < Double(ttl.components.seconds) {
        return true
    }
    try? FileManager.default.removeItem(atPath: destination.string)
    return false
}

/// Attempts a single download-or-wait cycle.
///
/// Returns `true` once `destination` is ready to use, `false` if the caller should retry
/// (e.g. because an abandoned lock file was cleared and a fresh attempt is needed).
private func downloadTestServerIfNeeded(
    to destination: FilePath,
    options: TimeSkippingTestServerOptions
) async throws -> Bool {
    if FileManager.default.fileExists(atPath: destination.string) {
        return true
    }

    let lockPath = FilePath(destination.string + ".downloading")
    let lockFile: FileDescriptor
    do {
        lockFile = try FileDescriptor.open(
            lockPath,
            .writeOnly,
            options: [.create, .exclusiveCreate],
            permissions: FilePermissions(rawValue: 0o755)
        )
    } catch Errno.fileExists {
        return try await waitForConcurrentDownload(lockPath: lockPath, destination: destination)
    }

    do {
        let info = try await resolveTestServerDownload(
            downloadVersion: options.downloadVersion,
            sdkName: options.sdkName,
            sdkVersion: options.sdkVersion
        )
        try await downloadArchive(from: info.archiveUrl, extracting: info.fileToExtract, into: lockFile)
        try lockFile.close()
        guard rename(lockPath.string, destination.string) == 0 else {
            throw TestServerProcessError.archiveDownloadFailed(
                url: info.archiveUrl,
                underlying: String(cString: strerror(errno))
            )
        }
    } catch {
        try? lockFile.close()
        try? FileManager.default.removeItem(atPath: lockPath.string)
        throw error
    }
    return true
}

/// Polls for a concurrently-downloading lock file to disappear, mirroring the Core SDK's
/// coordination protocol: an abandoned lock (no update in 90s) is cleared and retried,
/// otherwise wait up to 20s for the owning download to finish.
func waitForConcurrentDownload(lockPath: FilePath, destination: FilePath) async throws -> Bool {
    let lockAge = (try? FileManager.default.attributesOfItem(atPath: lockPath.string))
        .flatMap { $0[.modificationDate] as? Date }
        .map { Date.now.timeIntervalSince($0) }

    if let lockAge, lockAge > 90 {
        try? FileManager.default.removeItem(atPath: lockPath.string)
        return false
    }

    for _ in 0..<20 {
        try await Task.sleep(for: .seconds(1))
        if !FileManager.default.fileExists(atPath: lockPath.string) {
            return FileManager.default.fileExists(atPath: destination.string)
        }
    }
    throw TestServerProcessError.lockTimedOut(path: lockPath.string)
}

/// Downloads the `.tar.gz` archive at `urlString` and streams the single `fileToExtract`
/// member out of it into `destination`, by piping the downloaded bytes through the system `tar`.
private func downloadArchive(
    from urlString: String,
    extracting fileToExtract: String,
    into destination: FileDescriptor
) async throws {
    guard let url = URL(string: urlString) else {
        throw TestServerProcessError.archiveDownloadFailed(url: urlString, underlying: "invalid URL")
    }

    let archiveData: Data
    do {
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse, (200..<300).contains(httpResponse.statusCode) else {
            throw TestServerProcessError.invalidDownloadResponse(statusCode: (response as? HTTPURLResponse)?.statusCode ?? -1)
        }
        archiveData = data
    } catch let error as TestServerProcessError {
        throw error
    } catch {
        throw TestServerProcessError.archiveDownloadFailed(url: urlString, underlying: String(describing: error))
    }

    let result = try await Subprocess.run(
        .name("tar"),
        arguments: Arguments(["-x", "-z", "-f", "-", "-O", fileToExtract]),
        input: .array(Array(archiveData)),
        output: .fileDescriptor(destination, closeAfterSpawningProcess: false),
        error: .string(limit: 4096)
    )
    guard result.terminationStatus.isSuccess else {
        let exitCode: Int32
        if case .exited(let code) = result.terminationStatus {
            exitCode = code
        } else {
            exitCode = -1
        }
        throw TestServerProcessError.extractionFailed(exitCode: exitCode, standardError: result.standardError)
    }
}
#endif
