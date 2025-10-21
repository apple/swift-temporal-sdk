// swift-tools-version: 6.2

import CompilerPluginSupport
import PackageDescription

let package = Package(
    name: "swift-temporal-sdk",
    platforms: [
        .macOS(.v15),
        .iOS(.v18),
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
            url: "https://github.com/apple/swift-temporal-sdk/releases/download/temporal-sdk-core-682d441-1/temporal.artifactbundle.zip",
            checksum: "657ae88ac10ba93b6f1b282a30940d99c3df5a840473526570be6b01328c4afc"
        ),
        .binaryTarget(
            name: "BridgeDarwin",
            url: "https://github.com/apple/swift-temporal-sdk/releases/download/temporal-sdk-core-682d441-1/temporal.xcframework.zip",
            checksum: "7a6dd660d317b59be6ad79991c0ad73d8e5c809808f93777c8f13bdd439d87db"
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
                                .macCatalyst,
                                .iOS,
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

        // MARK: Examples

        .executableTarget(
            name: "GreetingExample",
            dependencies: [
                .target(name: "Temporal")
            ],
            path: "Examples/Greeting",
        ),
        .executableTarget(
            name: "MultipleActivitiesExample",
            dependencies: [
                .target(name: "Temporal")
            ],
            path: "Examples/MultipleActivities",
            exclude: ["README.md"],
        ),
        .executableTarget(
            name: "ErrorHandlingExample",
            dependencies: [
                .target(name: "Temporal")
            ],
            path: "Examples/ErrorHandling",
            exclude: ["README.md"],
        ),
        .executableTarget(
            name: "SignalExample",
            dependencies: [
                .target(name: "Temporal")
            ],
            path: "Examples/Signals",
            exclude: ["README.md"],
        ),
        .executableTarget(
            name: "AsyncActivitiesExample",
            dependencies: [
                .target(name: "Temporal")
            ],
            path: "Examples/AsyncActivities",
            exclude: ["README.md"],
        ),
        .executableTarget(
            name: "ScheduleExample",
            dependencies: [
                .target(name: "Temporal")
            ],
            path: "Examples/Schedule",
            exclude: ["README.md"],
        ),
        .executableTarget(
            name: "ChildWorkflowExample",
            dependencies: [
                .target(name: "Temporal")
            ],
            path: "Examples/ChildWorkflows",
            exclude: ["README.md"],
        ),

        // MARK: Tests

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
    ]
)

for target in package.targets
where [.executable, .test, .regular].contains(
    target.type
) {
    var settings = target.swiftSettings ?? []

    // https://github.com/apple/swift-evolution/blob/main/proposals/0335-existential-any.md
    // Require `any` for existential types.
    settings.append(.enableUpcomingFeature("ExistentialAny"))

    // https://github.com/swiftlang/swift-evolution/blob/main/proposals/0444-member-import-visibility.md
    settings.append(.enableUpcomingFeature("MemberImportVisibility"))

    // https://github.com/swiftlang/swift-evolution/blob/main/proposals/0409-access-level-on-imports.md
    settings.append(.enableUpcomingFeature("InternalImportsByDefault"))

    // https://github.com/swiftlang/swift-evolution/blob/main/proposals/0461-async-function-isolation.md
    settings.append(.enableUpcomingFeature("NonIsolatedNonSendingByDefault"))

    target.swiftSettings = settings
}
