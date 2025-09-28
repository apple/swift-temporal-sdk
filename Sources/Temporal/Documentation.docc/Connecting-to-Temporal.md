# Connecting to Temporal

Connect to Temporal clusters and configure client authentication for production
environments.

## Overview

The Temporal client serves as your application's gateway to interact with
Temporal services. Use it to start workflows, query workflow state,
send signals, and manage workflow lifecycles across different environments.

This article shows you how to establish connections to local development
and production instances. You'll learn to configure authentication,
handle connection lifecycle, and implement retry policies for robust client
operations.

## Connect to a local development server

For local development and testing, connect to a Temporal development server
that runs without transport security:

```swift
import Temporal
import GRPCNIOTransportHTTP2Posix
import Logging

let logger = Logger(label: "TemporalClient")

let client = try TemporalClient(
    target: .ipv4(address: "127.0.0.1", port: 7233),
    transportSecurity: .plaintext,
    configuration: .init(
        instrumentation: .init(serverHostname: "localhost")
    ),
    logger: logger
)

// Run the client
try await client.run()
```

A development server typically runs on `localhost:7233` with a plaintext
transport. This configuration provides no encryption and should **never** be
used in production environments.

## Connect to Temporal with mTLS

Most production Temporal servers require mutual TLS (mTLS) authentication which uses
client certificates. The example below illustrates how to configure your client with
the required certificates:

```swift
import X509
import Temporal
import GRPCNIOTransportHTTP2Posix

let logger = Logger(label: "TemporalClient")
let client = try await TemporalClient(
    transport: .http2NIOPosix(
        target: .dns(host: "temporal.example.com", port: 7233),
        transportSecurity: .mTLS(
            certificateReloader: TimedCertificateReloader(
                refreshInterval: .seconds(60*60),
                certificateSource: .init(
                    location: .file(path: "path/to/your/certificate.pem"),
                    format: .pem
                ),
                privateKeySource: .init(
                    location: .file(path: "path/to/your/private-key.pem"),
                    format: .pem
                    ),
                logger: logger
            )
        )
    ),
    configuration: .init(
        instrumentation: .init(serverHostname: "temporal.example.com")
    )
)

try await client.run()
```

For more advanced transport configuration, use the
``TemporalClient/connect(transport:configuration:isolation:logger:_:)`` method
and check out the [grpc-swift project](https://github.com/grpc/grpc-swift-2).

## Manage client lifecycle

Handle client startup and shutdown gracefully in your application using
[Swift ServiceLifecycle](https://github.com/swift-server/swift-service-lifecycle).
An instance of ``TemporalClient`` conforms to the `Service` protocol,
which you can include within the `ServiceGroup` your app runs, as show below:

```swift
import Logging
import Temporal
import ServiceLifecycle

@main
struct TemporalApplication {
    static func main() async throws {
        let logger = Logger(label: "TemporalApplication")

        let client = try TemporalClient(
            target: .dns(host: "temporal.example.com", port: 7233),
            transportSecurity: .mTLS(...),
            configuration: .init(...),
            logger: logger
        )
        
        // Runs the client in a group and listens for SIGTERM to gracefully
        // shutdown the client.
        try await ServiceGroup(
            services: [client],
            gracefulShutdownSignals: [.sigterm],
            logger: .init(label: "")
        ).run()
    }
}
```

By using the Swift Service Lifecycle to manage the service, your application shuts
down cleanly when it receives termination signals.
