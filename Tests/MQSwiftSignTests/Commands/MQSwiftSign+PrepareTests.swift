import Foundation
import MQAssert

@testable import MQSwiftSign

final class MQSwiftSign_Prepare_Tests: FeatureTests {
	override func commonPatches(_ patches: FeaturePatches) {
		super.commonPatches(patches)
		patches(use: Keychain.test())
	}

	func testShouldFailWhenCertificateIsInvalid() async {
		await test(
			throws: InvalidCertificate.self,
			execute: {
				let invalidBase64 = "a"
				var sut = try MQSwiftSign.Prepare.parse([invalidBase64])
				try sut.run()
			}
		)
	}

	func testShouldFailWhenCertificateIsEmpty() async {
		await test(
			throws: InvalidCertificate.self,
			execute: {
				let invalidBase64 = ""
				var sut = try MQSwiftSign.Prepare.parse([invalidBase64])
				try sut.run()
			}
		)
	}

	func testShouldFailIfCertificateIsMissing() {
		XCTAssertThrowsError(try MQSwiftSign.Prepare.parse([]), "Should throw exception when no argument is provided")
	}

	func testShouldPassArguments() async throws {
		let parameters = [
			mockedCertificate,
			"--keychain-name", keychainName,
			"--keychain-password", keychainPassword,
			"--cert-password", certPassword,
			"--applications", applications[0], applications[1],
			"--custom-acls", customAcls[0], customAcls[1],
		]

		await test(
			patches: { (patches: FeaturePatches) -> () in
				patches(
					patch: \Keychain.setup,
					with: { keychainName, keychainPassword in
						XCTAssertEqual(keychainName, self.keychainName)
						XCTAssertEqual(keychainPassword, self.keychainPassword)
					}
				)
				patches(
					patch: \Keychain.import,
					with: { data, password, applications in
						XCTAssertEqual(data, Data(base64Encoded: self.mockedCertificate))
						XCTAssertEqual(password, self.certPassword)
						XCTAssertEqual(applications, ["app1", "app2"])
					}
				)
				patches(
					patch: \Keychain.setACLs,
					with: { password, customPartitions in
						XCTAssertEqual(password, self.keychainPassword)
						XCTAssertEqual(customPartitions, ["acl1", "acl2"])
					}
				)
			},
			execute: { features in
				var sut = try MQSwiftSign.Prepare.parse(parameters)
				try sut.run(features)
			}
		)
	}

	func testShouldInstallProvisioning() async {
		let parameters = [
			mockedCertificate,
			"--keychain-name", keychainName,
			"--provisioning-path", provisioningPath,
		]
		await test(
			patches: { patches, executed in
				patches(
					patch: \ProvisioningInstaller.install,
					with: { _, _ in
						executed()
					}
				)
			},
			executedPrepared: 1,
			execute: { features in
				var sut = try MQSwiftSign.Prepare.parse(parameters)
				try sut.run(features)
			}
		)
	}
}

extension MQSwiftSign_Prepare_Tests {
	var mockedCertificate: String {
		"randomText".data(using: .unicode)!.base64EncodedString()
	}

	var keychainPassword: String {
		"keychainPassword"
	}
	var certPassword: String {
		"certPassword"
	}
	var keychainName: String {
		"keychainName"
	}
	var applications: [String] {
		["app1", "app2"]
	}
	var customAcls: [String] {
		["acl1", "acl2"]
	}
	var provisioningPath: String {
		"provisioningPath"
	}
}
