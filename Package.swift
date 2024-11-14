// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
	name: "MQSwiftSign",
	platforms: [
		.macOS(.v13),
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
		.package(url: "https://github.com/apple/swift-argument-parser", from: "1.5.0"),
        .package(url: "https://github.com/miquido/MQTagged", .upToNextMinor(from: "0.1.0")),
        .package(url: "https://github.com/miquido/MQ-iOS.git", .upToNextMinor(from: "0.12.0")),
        .package(url: "https://github.com/miquido/MQDo", .upToNextMinor(from: "0.11.0")),
		.package(url: "https://github.com/tuist/XcodeProj.git", .upToNextMajor(from: "8.24.0")),
		.package(url: "https://github.com/apple/swift-format", branch: "main")
	],
	targets: [
		.executableTarget(
			name: "MQSwiftSign",
			dependencies: [
				.product(name: "ArgumentParser", package: "swift-argument-parser"),
				.product(name: "MQTagged", package: "MQTagged"),
				.product(name: "MQ", package: "MQ-iOS"),
				.product(name: "MQDo", package: "MQDo"),
				"MQSwiftSignC",
				"XcodeProj",
			]),
		.target(
			name: "MQSwiftSignC",
			publicHeadersPath: "include",
			cSettings: [
				.headerSearchPath("include")
			]
		),
		.testTarget(
			name: "MQSwiftSignTests",
			dependencies: [
				"MQSwiftSign",
				.product(name: "MQAssert", package: "MQDo"),
				.product(name: "MQ", package: "MQ-iOS")
			]
		)
	]
)
