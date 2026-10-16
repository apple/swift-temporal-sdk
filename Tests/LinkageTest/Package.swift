// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "linkage-test",
    platforms: [
        .macOS(.v15), .iOS(.v18),
    ],
    dependencies: [
        .package(name: "swift-temporal-sdk", path: "../..", traits: [])
    ],
    targets: [
        .executableTarget(
            name: "linkageTest",
            dependencies: [
                .product(name: "Temporal", package: "swift-temporal-sdk")
            ]
        )
    ]
)
