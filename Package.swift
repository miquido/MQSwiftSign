// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MQSwiftSign",
    platforms: [
        .macOS(.v12),
    ],
    products: [
        .executable(
            name: "MQSwiftSign",
            targets: ["MQSwiftSign"]),
        .library(
            name: "MQSwiftSignC",
            targets: ["MQSwiftSignC"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.0.0"),
        .package(url: "https://github.com/miquido/MQTagged", from: "0.1.0"),
        .package(url: "https://github.com/miquido/MQ-iOS.git", .upToNextMajor(from: "0.9.0")),
        .package(url: "https://github.com/apple/swift-format", branch: "main")
    ],
    targets: [
        .executableTarget(
            name: "MQSwiftSign",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "MQTagged", package: "MQTagged"),
                .product(name: "MQ", package: "MQ-iOS"),
                "MQSwiftSignC"
            ]),
        .target(
            name: "MQSwiftSignC",
            publicHeadersPath: "include",
            cSettings: [
                .headerSearchPath("include")
            ]
        )
    ]
)
