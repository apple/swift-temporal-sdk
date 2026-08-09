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
package enum TestServerProcessError: Error, Sendable, CustomStringConvertible {
    case invalidDownloadResponse(statusCode: Int)
    case downloadResolutionFailed(underlying: String)
    case archiveDownloadFailed(url: String, underlying: String)
    case extractionFailed(exitCode: Int32, standardError: String)
    case lockTimedOut(path: String)
    case processFailedToStart(underlying: String)
    case reachabilityTimeout(target: String)

    package var description: String {
        switch self {
        case .invalidDownloadResponse(let statusCode):
            "Test server download resolution returned an unexpected status code \(statusCode)."
        case .downloadResolutionFailed(let underlying):
            "Failed to resolve the test server download location: \(underlying)"
        case .archiveDownloadFailed(let url, let underlying):
            "Failed to download the test server archive from \(url): \(underlying)"
        case .extractionFailed(let exitCode, let standardError):
            "Failed to extract the test server binary (tar exited with \(exitCode)): \(standardError)"
        case .lockTimedOut(let path):
            "Timed out waiting for a concurrent test server download to finish at \(path)."
        case .processFailedToStart(let underlying):
            "Failed to start the test server process: \(underlying)"
        case .reachabilityTimeout(let target):
            "Test server did not become reachable at \(target) in time."
        }
    }
}
#endif
