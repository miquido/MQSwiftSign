import Foundation
import PathKit
import XCTest
import XcodeProj

@testable import MQSwiftSign

final class DependencyTreeTests: XCTestCase {
    
	func test_givenTargetWithConfiguration_whenDevelopmentTeamIsMissing_shouldFail() throws {
		let treeNode = DependencyTree(targetName: "TestTarget", settings: [:], dependencies: [])
		assertThrowsError(
			try treeNode.exportOptionsPlistContent(),
			ExportPlistContentCreationFailed.error()
		)
	}

	func test_givenTargetWithConfiguration_whenCodeSignIdentityIsMissing_shouldFail() throws {
		let treeNode = DependencyTree(
			targetName: "TestTarget", settings: ["DEVELOPMENT_TEAM": "SOME TEAM"], dependencies: [])
		assertThrowsError(
			try treeNode.exportOptionsPlistContent(),
			ExportPlistContentCreationFailed.error()
		)
	}

	func test_givenTargetWithConfiguration_whenCodeSignStyleIsMissing_shouldFallbackToManualStyle() throws {
		let treeNode = DependencyTree(
			targetName: "TestTarget",
			settings: [
				"DEVELOPMENT_TEAM": "SOME TEAM",
				"CODE_SIGN_IDENTITY": "SOME IDENTITY",
			],
			dependencies: []
		)
		let options = try treeNode.exportOptionsPlistContent()
		XCTAssertEqual(options.properties[.signingStyle] as? String, "manual")
	}

	func test_givenTargetWithConfiguration_withRequiredProperties_shouldReturnExtractedOptions() throws {
		let treeNode = DependencyTree(
			targetName: "TestTarget",
			settings: [
				"DEVELOPMENT_TEAM": "SOME TEAM",
				"CODE_SIGN_IDENTITY": "SOME IDENTITY",
				"CODE_SIGN_STYLE": "Manual",
			],
			dependencies: []
		)
		let options = try treeNode.exportOptionsPlistContent()
		XCTAssertEqual(options.properties.count, 7)
		XCTAssertEqual(options.properties[.teamID] as! String, "SOME TEAM")
		XCTAssertEqual(options.properties[.signingStyle] as! String, "manual")
		XCTAssertEqual(options.properties[.signingCertificate] as! String, "SOME IDENTITY")
		XCTAssertFalse(options.properties[.uploadBitcode] as! Bool)
		XCTAssertTrue(options.properties[.compileBitcode] as! Bool)
		XCTAssertTrue(options.properties[.uploadSymbols] as! Bool)
		XCTAssertEqual(options.properties[.provisioningProfiles] as! [String: String], [:])
	}

	func test_givenTargetWithDependencies_withProvisioning_shouldBeIncludedInMapping() throws {
		let tree: DependencyTree = .root(
			withBundleId: "com.example.main",
			provisioningSpecifier: "PROD specifier",
			children: [
				.node(withBundleId: "com.example.notification", provisioningSpecifier: "PROD notification specifier"),
				.node(withBundleId: "com.example.lib"),
			]
		)

		let options = try tree.exportOptionsPlistContent()
		XCTAssertEqual(
			options.properties[.provisioningProfiles] as! [String: String],
			[
				"com.example.main": "PROD specifier",
				"com.example.notification": "PROD notification specifier",
			])
	}
}

private extension DependencyTree {
	static func root(
		withBundleId bundleId: String,
		provisioningSpecifier: String,
		children: [DependencyTree] = []
	) -> DependencyTree {
		return DependencyTree(
			targetName: bundleId,
			settings: [
				"PRODUCT_BUNDLE_IDENTIFIER": bundleId,
				"PROVISIONING_PROFILE_SPECIFIER": provisioningSpecifier,
				"DEVELOPMENT_TEAM": "SOME TEAM",
				"CODE_SIGN_IDENTITY": "SOME IDENTITY",
			],
			dependencies: children
		)
	}

	static func node(
		withBundleId bundleId: String,
		provisioningSpecifier: String? = nil,
		children: [DependencyTree] = []
	) -> DependencyTree {
		var settings = [
			"PRODUCT_BUNDLE_IDENTIFIER": bundleId
		]
		if let provisioningSpecifier = provisioningSpecifier {
			settings["PROVISIONING_PROFILE_SPECIFIER"] = provisioningSpecifier
		}
		return DependencyTree(targetName: bundleId, settings: settings, dependencies: children)
	}
}
