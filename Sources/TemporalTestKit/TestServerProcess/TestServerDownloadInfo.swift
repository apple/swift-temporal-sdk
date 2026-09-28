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

/// The response from the `temporal.download` artifact resolution service.
struct TestServerDownloadInfo: Decodable, Sendable {
    let archiveUrl: String
    let fileToExtract: String
}

enum TestServerDownloadPlatform {
    static var current: String {
        #if os(macOS)
        "darwin"
        #else
        "linux"
        #endif
    }
}

enum TestServerDownloadArch {
    static var current: String {
        #if arch(x86_64)
        "amd64"
        #elseif arch(arm64)
        "arm64"
        #else
        #error("Unsupported architecture for downloading the test server binary.")
        #endif
    }
}

func testServerDownloadURL(
    downloadVersion: String,
    sdkName: String,
    sdkVersion: String
) -> URL {
    var components = URLComponents(string: "https://temporal.download/temporal-test-server/\(downloadVersion)")!
    var queryItems = [
        URLQueryItem(name: "arch", value: TestServerDownloadArch.current),
        URLQueryItem(name: "platform", value: TestServerDownloadPlatform.current),
    ]
    if downloadVersion == "default" {
        queryItems.append(URLQueryItem(name: "sdk-name", value: sdkName))
        queryItems.append(URLQueryItem(name: "sdk-version", value: sdkVersion))
    }
    components.queryItems = queryItems
    return components.url!
}

func resolveTestServerDownload(
    downloadVersion: String,
    sdkName: String,
    sdkVersion: String
) async throws -> TestServerDownloadInfo {
    let url = testServerDownloadURL(downloadVersion: downloadVersion, sdkName: sdkName, sdkVersion: sdkVersion)

    let (data, response): (Data, URLResponse)
    do {
        (data, response) = try await URLSession.shared.data(from: url)
    } catch {
        throw TestServerProcessError.downloadResolutionFailed(underlying: String(describing: error))
    }

    guard let httpResponse = response as? HTTPURLResponse, (200..<300).contains(httpResponse.statusCode) else {
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
        throw TestServerProcessError.invalidDownloadResponse(statusCode: statusCode)
    }

    do {
        return try JSONDecoder().decode(TestServerDownloadInfo.self, from: data)
    } catch {
        throw TestServerProcessError.downloadResolutionFailed(underlying: String(describing: error))
    }
}
#endif
