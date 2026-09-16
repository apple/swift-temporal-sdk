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

/// Spawns the `temporal-test-server` binary at `executablePath`, waits until it's reachable,
/// hands the `"host:port"` connect target to `body`, and gracefully tears the process down
/// once `body` returns or throws.
func withRunningTestServer<Result: Sendable>(
    executablePath: FilePath,
    extraArguments: [String],
    _ body: (String) async throws -> Result
) async throws -> Result {
    let port = try reserveFreePort()
    let target = "127.0.0.1:\(port)"
    let teardownSequence: [TeardownStep] = [.gracefulShutDown(allowedDurationToNextStep: .seconds(5))]

    let executionResult = try await Subprocess.run(
        .path(executablePath),
        arguments: Arguments([String(port)] + extraArguments),
        input: .none,
        output: .currentStandardOutput,
        error: .currentStandardError
    ) { execution in
        do {
            try await waitUntilReachable(target: target)
            let result = try await body(target)
            await execution.teardown(using: teardownSequence)
            return result
        } catch {
            await execution.teardown(using: teardownSequence)
            throw error
        }
    }
    return executionResult.closureResult
}

#if canImport(Glibc)
private let socketStreamType = Int32(SOCK_STREAM.rawValue)
#else
private let socketStreamType = SOCK_STREAM
#endif

/// Binds a TCP socket to an OS-assigned port on `0.0.0.0`, reads the assigned port back,
/// then closes the socket so the test server binary can bind it — the same
/// bind-then-release strategy the Core SDK's Rust implementation uses.
private func reserveFreePort() throws -> UInt16 {
    let handle = socket(AF_INET, socketStreamType, 0)
    guard handle >= 0 else {
        throw TestServerProcessError.processFailedToStart(underlying: "socket() failed: \(String(cString: strerror(errno)))")
    }
    defer { close(handle) }

    var address = sockaddr_in()
    address.sin_family = sa_family_t(AF_INET)
    address.sin_addr.s_addr = INADDR_ANY
    address.sin_port = 0
    let bindResult = withUnsafePointer(to: &address) { pointer in
        pointer.withMemoryRebound(to: sockaddr.self, capacity: 1) { sockaddrPointer in
            bind(handle, sockaddrPointer, socklen_t(MemoryLayout<sockaddr_in>.size))
        }
    }
    guard bindResult == 0 else {
        throw TestServerProcessError.processFailedToStart(underlying: "bind() failed: \(String(cString: strerror(errno)))")
    }

    var boundAddress = sockaddr_in()
    var length = socklen_t(MemoryLayout<sockaddr_in>.size)
    let nameResult = withUnsafeMutablePointer(to: &boundAddress) { pointer in
        pointer.withMemoryRebound(to: sockaddr.self, capacity: 1) { sockaddrPointer in
            getsockname(handle, sockaddrPointer, &length)
        }
    }
    guard nameResult == 0 else {
        throw TestServerProcessError.processFailedToStart(underlying: "getsockname() failed: \(String(cString: strerror(errno)))")
    }
    return UInt16(bigEndian: boundAddress.sin_port)
}

/// Polls `target` every 100ms for up to 5 seconds, mirroring the Core SDK's readiness check.
private func waitUntilReachable(target: String) async throws {
    let parts = target.split(separator: ":", maxSplits: 1)
    guard parts.count == 2, let port = UInt16(parts[1]) else {
        throw TestServerProcessError.reachabilityTimeout(target: target)
    }
    let host = String(parts[0])

    for _ in 0..<50 {
        if isReachable(host: host, port: port) {
            return
        }
        try await Task.sleep(for: .milliseconds(100))
    }
    throw TestServerProcessError.reachabilityTimeout(target: target)
}

private func isReachable(host: String, port: UInt16) -> Bool {
    let handle = socket(AF_INET, socketStreamType, 0)
    guard handle >= 0 else {
        return false
    }
    defer { close(handle) }

    var address = sockaddr_in()
    address.sin_family = sa_family_t(AF_INET)
    address.sin_port = port.bigEndian
    guard inet_pton(AF_INET, host, &address.sin_addr) == 1 else {
        return false
    }

    let connectResult = withUnsafePointer(to: &address) { pointer in
        pointer.withMemoryRebound(to: sockaddr.self, capacity: 1) { sockaddrPointer in
            connect(handle, sockaddrPointer, socklen_t(MemoryLayout<sockaddr_in>.size))
        }
    }
    return connectResult == 0
}
#endif
