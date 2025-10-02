// swift-tools-version: 6.2

import CompilerPluginSupport
import PackageDescription

let package = Package(
    name: "swift-temporal-sdk",
    platforms: [
        .macOS(.v15),
        .iOS(.v18),
        .tvOS(.v18),
        .watchOS(.v11),
    ],
    products: [
        .library(
            name: "Temporal",
            targets: [
                "Temporal"
            ]
        ),
        .library(name: "TemporalTestKit", targets: ["TemporalTestKit"]),
    ],
    traits: [
        .default(enabledTraits: ["GRPCNIOTransport"]),
        .init(
            name: "GRPCNIOTransport",
            description: """
                Provides convenience methods for the worker and client using
                the NIO based transports.
                """
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-protobuf.git", from: "1.29.0"),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.6.0"),
        .package(url: "https://github.com/apple/swift-metrics.git", from: "2.7.0"),
        .package(url: "https://github.com/apple/swift-distributed-tracing.git", from: "1.2.0"),
        .package(url: "https://github.com/swift-otel/swift-otel-semantic-conventions.git", from: "1.34.2"),
        .package(url: "https://github.com/apple/swift-certificates.git", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-async-algorithms", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-collections.git", from: "1.0.0"),
        .package(url: "https://github.com/swiftlang/swift-syntax.git", from: "601.0.1"),
        .package(url: "https://github.com/grpc/grpc-swift-2.git", from: "2.0.0"),
        .package(url: "https://github.com/grpc/grpc-swift-nio-transport.git", from: "2.0.0"),
        .package(url: "https://github.com/grpc/grpc-swift-protobuf.git", from: "2.0.0"),
        .package(url: "https://github.com/grpc/grpc-swift-extras.git", from: "2.0.0"),
        .package(url: "https://github.com/swift-server/swift-service-lifecycle.git", from: "2.0.0"),
        .package(url: "https://github.com/apple/swift-configuration.git", .upToNextMinor(from: "0.1.0"), traits: []),
    ],
    targets: [
        .binaryTarget(
            name: "Bridge",
            url: "https://github.com/apple/swift-temporal-sdk/releases/download/temporal-sdk-core-682d441/temporal.artifactbundle.zip",
            checksum: "a457355ef39ef2d8609221e632682bbc06cfeb7a57691c96422fafa7a6350a39"
        ),
        .binaryTarget(
            name: "BridgeDarwin",
            url: "https://github.com/apple/swift-temporal-sdk/releases/download/temporal-sdk-core-682d441/temporal.xcframework.zip",
            checksum: "edac56be6bf723f7f46e5dd13af59c9192e2660a2bf74953b96fa807abb54688"
        ),
        .target(
            name: "Temporal",
            dependencies: [
                .product(name: "AsyncAlgorithms", package: "swift-async-algorithms"),
                .product(name: "DequeModule", package: "swift-collections"),
                .product(name: "SwiftProtobuf", package: "swift-protobuf"),
                .product(name: "Logging", package: "swift-log"),
                .product(name: "X509", package: "swift-certificates"),
                .product(name: "GRPCCore", package: "grpc-swift-2"),
                .product(name: "GRPCProtobuf", package: "grpc-swift-protobuf"),
                .product(name: "GRPCOTelTracingInterceptors", package: "grpc-swift-extras"),
                .product(name: "GRPCServiceLifecycle", package: "grpc-swift-extras"),
                .product(name: "ServiceLifecycle", package: "swift-service-lifecycle"),
                .product(name: "Configuration", package: "swift-configuration"),
                .product(
                    name: "GRPCNIOTransportHTTP2",
                    package: "grpc-swift-nio-transport",
                    condition: .when(traits: ["GRPCNIOTransport"])
                ),
                .target(name: "Bridge", condition: .when(platforms: [.linux])),
                .target(
                    name: "BridgeDarwin",
                    condition:
                        .when(
                            platforms: [
                                .macOS,
                                .iOS,
                                .tvOS,
                                .watchOS,
                                .visionOS,
                            ]
                        )
                ),
                .target(name: "TemporalMacros"),
                .target(name: "TemporalInstrumentation"),
                .target(name: "CConstants"),
            ],
            linkerSettings: [
                .linkedFramework("SystemConfiguration", .when(platforms: [.macOS]))
            ]
        ),
        .target(
            name: "TemporalInstrumentation",
            dependencies: [
                .product(name: "Logging", package: "swift-log"),
                .product(name: "GRPCCore", package: "grpc-swift-2"),
                .product(name: "Metrics", package: "swift-metrics"),
                .product(name: "Tracing", package: "swift-distributed-tracing"),
                .product(name: "OTelSemanticConventions", package: "swift-otel-semantic-conventions"),
            ]
        ),
        .target(
            name: "TemporalTestKit",
            dependencies: [
                .product(name: "GRPCNIOTransportHTTP2", package: "grpc-swift-nio-transport"),
                .target(name: "Temporal"),
            ]
        ),
        .target(
            name: "CConstants",
            path: "Sources/CConstants",
            publicHeadersPath: "include",
            cSettings: [
                .define(
                    "SWIFT_TEMPORAL_SDK_VERSION",
                    to: {
                        // The `swift-temporal` SDK version extracted from the git tag
                        let sdkVersion = {
                            if let git = Context.gitInformation {
                                let swiftTemporalSdkVersion =
                                    if let tag = git.currentTag {
                                        tag
                                    } else if git.hasUncommittedChanges {
                                        "\(git.currentCommit) (modified)"
                                    } else {
                                        git.currentCommit
                                    }

                                return swiftTemporalSdkVersion
                            }

                            return "unknown"
                        }()

                        // escape potential backslashes or quotes
                        let sdkVersionEscaped =
                            sdkVersion
                            // Foundation's `.replacingOccurrences()` not available in package manifest
                            .split(separator: "\\", omittingEmptySubsequences: false)
                            .joined(separator: "\\\\")
                            .split { $0 == "\"" }
                            .joined(separator: "\\\"")

                        return "\"" + sdkVersionEscaped + "\""  // wrap in real quotes
                    }()
                )
            ]
        ),
        .macro(
            name: "TemporalMacros",
            dependencies: [
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftSyntaxBuilder", package: "swift-syntax"),
                .product(name: "SwiftDiagnostics", package: "swift-syntax"),
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
            ]
        ),
        .testTarget(
            name: "TemporalTests",
            dependencies: [
                .product(name: "GRPCNIOTransportHTTP2", package: "grpc-swift-nio-transport"),
                "Temporal",
                "TemporalTestKit",
            ]
        ),
        .testTarget(
            name: "TemporalMacrosTests",
            dependencies: [
                "TemporalMacros",
                .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
            ]
        ),

        // Examples
        .executableTarget(
            name: "GreetingExample",
            dependencies: [
                "Temporal",
                .product(name: "GRPCNIOTransportHTTP2", package: "grpc-swift-nio-transport"),
            ],
            path: "Examples/Greeting"
        ),
        .executableTarget(
            name: "MultipleActivitiesExample",
            dependencies: [
                "Temporal",
                .product(name: "GRPCNIOTransportHTTP2", package: "grpc-swift-nio-transport"),
            ],
            path: "Examples/MultipleActivities",
            exclude: ["README.md"]
        ),
        .executableTarget(
            name: "ErrorHandlingExample",
            dependencies: [
                "Temporal",
                .product(name: "GRPCNIOTransportHTTP2", package: "grpc-swift-nio-transport"),
            ],
            path: "Examples/ErrorHandling",
            exclude: ["README.md"]
        ),
        .executableTarget(
            name: "SignalExample",
            dependencies: [
                "Temporal",
                .product(name: "GRPCNIOTransportHTTP2", package: "grpc-swift-nio-transport"),
            ],
            path: "Examples/Signals",
            exclude: ["README.md"]
        ),
        .executableTarget(
            name: "AsyncActivitiesExample",
            dependencies: [
                "Temporal",
                .product(name: "GRPCNIOTransportHTTP2", package: "grpc-swift-nio-transport"),
            ],
            path: "Examples/AsyncActivities",
            exclude: ["lemon-dataset/", ".gitignore", "README.md"]
        ),
        .executableTarget(
            name: "ScheduleExample",
            dependencies: [
                "Temporal",
                .product(name: "GRPCNIOTransportHTTP2", package: "grpc-swift-nio-transport"),
            ],
            path: "Examples/Schedule",
            exclude: ["README.md"]
        ),
        .executableTarget(
            name: "ChildWorkflowExample",
            dependencies: [
                "Temporal",
                .product(name: "GRPCNIOTransportHTTP2", package: "grpc-swift-nio-transport"),
            ],
            path: "Examples/ChildWorkflows",
            exclude: ["README.md"]
        ),
    ]
)
