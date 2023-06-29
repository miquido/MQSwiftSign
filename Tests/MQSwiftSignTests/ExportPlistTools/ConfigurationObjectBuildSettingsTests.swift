import Foundation
import XCTest
import PathKit
@testable import MQSwiftSign

final class ConfigurationObjectBuildSettingsTests: XCTestCase {
	override func tearDown() {
		super.tearDown()
		try? entitlementsPath.delete()
	}

	func test_givenValidPropertiesWithICloudEnv_shouldReturnICloudEnvName() throws {
		try createEntitlementsFile(withValues: ["com.apple.developer.icloud-container-environment": "ENVIRONMENT"])
		let properties = ["CODE_SIGN_ENTITLEMENTS": entitlementsPath.string]
		let options = ConfigurationObjectBuildSettings(properties: properties)
		XCTAssertEqual(options.iCloudContainerEnvironment, "ENVIRONMENT")
	}

	func test_givenValidPropertiesWithoutICloudEnv_shouldReturnNil() throws {
		try createEntitlementsFile(withValues: [:])
		let properties = ["CODE_SIGN_ENTITLEMENTS": entitlementsPath.string]
		let options = ConfigurationObjectBuildSettings(properties: properties)
		XCTAssertNil(options.iCloudContainerEnvironment)
	}

	func test_givenInvalidProperties_shouldReturnNil() throws {
		try createEntitlementsFile(withValues: [:])
		let properties = ["CODE_SIGN_ENTITLEMENTS": "INVALID_PATH"]
		let options = ConfigurationObjectBuildSettings(properties: properties)
		XCTAssertNil(options.iCloudContainerEnvironment)
	}

	func test_givenNoBundleId_provisioningSpecifierShouldBeNil() {
		let options = ConfigurationObjectBuildSettings(properties: [:])
		XCTAssertNil(try options.provisioningProfileSpecifier)
	}

	func test_givenNoPlatformAndGenericSpecifier_provisioningSpecifierShouldBeNil() {
		let options = ConfigurationObjectBuildSettings(properties: ["PRODUCT_BUNDLE_IDENTIFIER": "com.example.app"])
		XCTAssertNil(try options.provisioningProfileSpecifier)
	}

	func test_givenBothPlatformAndGenericSpecifier_genericSpecifierShouldBeUsed() {
		let options = ConfigurationObjectBuildSettings(
			properties: [
				"PRODUCT_BUNDLE_IDENTIFIER": "com.example.app",
				"PROVISIONING_PROFILE_SPECIFIER": "generic",
				"PROVISIONING_PROFILE_SPECIFIER[sdk=iphoneos*]": "platform",
			]
		)
		XCTAssertEqual(try! options.provisioningProfileSpecifier?.provisioning, "generic")
		XCTAssertEqual(try! options.provisioningProfileSpecifier?.bundle.value, "com.example.app")
	}

	func test_givenEmptySpecifier_shouldReturnNil() {
		let options = ConfigurationObjectBuildSettings(
			properties: [
				"PRODUCT_BUNDLE_IDENTIFIER": "com.example.app",
				"PROVISIONING_PROFILE_SPECIFIER": ""
			]
		)
		XCTAssertNil(try options.provisioningProfileSpecifier)
	}

	func test_givenInvalidBundleId_shouldThrowError() throws {
		let options = ConfigurationObjectBuildSettings(
			properties: [
				"PRODUCT_BUNDLE_IDENTIFIER": "#",
				"PROVISIONING_PROFILE_SPECIFIER": "generic"
			]
		)
		assertThrowsError(try options.provisioningProfileSpecifier, InvalidBundleID.error())
	}
}

private extension ConfigurationObjectBuildSettingsTests {
	var entitlementsPath: Path {
		Path(#file).parent() + "Test.entitlements"
	}

	func createEntitlementsFile(withValues: [String: Any]) throws {
		let data = try PropertyListSerialization.data(fromPropertyList: withValues, format: .xml, options: 0)
		try data.write(to: entitlementsPath.url)
	}
}
