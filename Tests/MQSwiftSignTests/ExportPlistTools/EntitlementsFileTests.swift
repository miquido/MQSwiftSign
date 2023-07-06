import Foundation
import PathKit
import XCTest

@testable import MQSwiftSign

final class EntitlementsFileTests: XCTestCase {
	override func tearDown() {
		super.tearDown()
		try? testPath.delete()
	}

	func test_givenInvalidEntitlementsPath_shouldFailWithError() {
		let entitlements = EntitlementsFile(path: "invalid/path")
		assertThrowsError(try entitlements.getICloudContainerEnvironment(), NoSuchFile.error())
	}

	func test_givenValidEntitlementsPath_withInvalidContents_shouldFailWithError() throws {
		try Data().write(to: testPath.url)
		let entitlements = EntitlementsFile(path: EntitlementsPath(testPath.string)!)
		assertThrowsError(try entitlements.getICloudContainerEnvironment(), ExportPlistContentCreationFailed.error())
	}

	func test_givenValidEntitlementsPath_withValidContents_shouldReturnICloudContainerEnvironment() throws {
		let entitlementsContents = """
			<?xml version="1.0" encoding="UTF-8"?>
			<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
				"http://www.apple.com/DTDs/PropertyList-1.0.dtd">
			<plist version="1.0">
				<dict>
					<key>com.apple.developer.icloud-container-environment</key>
					<string>Development</string>
				</dict>
			</plist>
			"""
		try entitlementsContents.write(to: testPath.url, atomically: true, encoding: .utf8)
		let entitlements = EntitlementsFile(path: EntitlementsPath(testPath.string)!)
		XCTAssertEqual(try entitlements.getICloudContainerEnvironment(), ICloudContainerEnvironment("Development"))
	}
}

private extension EntitlementsFileTests {
	var testPath: Path {
		Path(#file).parent() + "test.path"
	}
}
