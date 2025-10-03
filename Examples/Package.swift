// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "TemporalExamples",
    platforms: [
        .macOS(.v15)
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-temporal-sdk.git", from: "0.1.0")
    ],
    targets: [
        .executableTarget(
            name: "GreetingExample",
            dependencies: [
                .product(name: "Temporal", package: "swift-temporal-sdk")
            ],
            path: "Greeting",
            swiftSettings: [
                .define("GRPCNIOTransport")
            ]
        ),
        .executableTarget(
            name: "MultipleActivitiesExample",
            dependencies: [
                .product(name: "Temporal", package: "swift-temporal-sdk")
            ],
            path: "MultipleActivities",
            exclude: ["README.md"],
            swiftSettings: [
                .define("GRPCNIOTransport")
            ]
        ),
        .executableTarget(
            name: "ErrorHandlingExample",
            dependencies: [
                .product(name: "Temporal", package: "swift-temporal-sdk")
            ],
            path: "ErrorHandling",
            exclude: ["README.md"],
            swiftSettings: [
                .define("GRPCNIOTransport")
            ]
        ),
        .executableTarget(
            name: "SignalExample",
            dependencies: [
                .product(name: "Temporal", package: "swift-temporal-sdk")
            ],
            path: "Signals",
            exclude: ["README.md"],
            swiftSettings: [
                .define("GRPCNIOTransport")
            ]
        ),
        .executableTarget(
            name: "AsyncActivitiesExample",
            dependencies: [
                .product(name: "Temporal", package: "swift-temporal-sdk")
            ],
            path: "AsyncActivities",
            exclude: ["README.md"],
            swiftSettings: [
                .define("GRPCNIOTransport")
            ]
        ),
        .executableTarget(
            name: "ScheduleExample",
            dependencies: [
                .product(name: "Temporal", package: "swift-temporal-sdk")
            ],
            path: "Schedule",
            exclude: ["README.md"],
            swiftSettings: [
                .define("GRPCNIOTransport")
            ]
        ),
        .executableTarget(
            name: "ChildWorkflowExample",
            dependencies: [
                .product(name: "Temporal", package: "swift-temporal-sdk")
            ],
            path: "ChildWorkflows",
            exclude: ["README.md"],
            swiftSettings: [
                .define("GRPCNIOTransport")
            ]
        ),
    ]
)
