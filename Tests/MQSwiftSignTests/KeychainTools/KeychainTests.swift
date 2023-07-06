import Foundation

@testable import MQSwiftSign

final class KeychainTests: FeatureTests {
	override func commonPatches(_ patches: FeaturePatches) {
		super.commonPatches(patches)
		patches(use: SecKeychainAPI.test)
		patches(use: SecItemAPI.placeholder)
	}

	func testLoadingExistingKeychain() async {
		await test(
			SystemKeychain.loader(),
			executedPreparedUsing: keychainName,
			when: { patches, executed in
				patches(
					patch: \SecKeychainAPI.get,
					with: { name in
						executed(name)
						return nil
					}
				)
			},
			executing: { (feature: Keychain) in
				try feature.setup(keychainName: self.keychainName, keychainPassword: self.keychainPassword)
			}
		)
	}

	func testCreatingNewKeychain() async {
		let createExecution = expectation(description: "Should attempt to create new keychain")
		let addToSearchListExecution = expectation(description: "Should attempt to add keychain to search list")
		let keychainMock: CFWrapper<SecKeychain> = .empty

		await test(
			SystemKeychain.loader(),
			when: { patches in
				patches(
					patch: \SecKeychainAPI.get,
					with: always(nil)
				)
				patches(
					patch: \SecKeychainAPI.create,
					with: { name, password in
						XCTAssertEqual(name, self.keychainName)
						XCTAssertEqual(password, self.keychainPassword)
						createExecution.fulfill()
						return .empty
					}
				)
				patches(
					patch: \SecKeychainAPI.addToSearchList,
					with: { keychain in
						XCTAssertEqual(keychain, keychainMock)
						addToSearchListExecution.fulfill()
					}
				)
			},
			executing: { (feature: Keychain) in
				try feature.setup(keychainName: self.keychainName, keychainPassword: self.keychainPassword)
			}
		)
		await fulfillment(of: [createExecution, addToSearchListExecution], timeout: 1)
	}

	func shouldFailWhenAddingToSearchListFails() async {
		await test(
			SystemKeychain.loader(),
			throws: KeychainSetPropertiesFailed.self,
			when: { patches in
				patches(
					patch: \SecKeychainAPI.addToSearchList,
					with: alwaysThrowing(KeychainSetPropertiesFailed.error())
				)
			},
			executing: { (feature: Keychain) in
				try feature.setup(keychainName: self.keychainName, keychainPassword: self.keychainPassword)
			}
		)
	}

	func testShouldFailSettingACLsWhenKeychainIsNotSetUp() async {
		await test(
			SystemKeychain.loader(),
			throws: AccessFailed.self,
			executing: { (feature: Keychain) in
				try feature.setACLs(using: self.keychainPassword, with: [])
			}
		)
	}

	func testShouldFailSettingACLsWhenItemIsNotFound() async {
		await test(
			SystemKeychain.loader(),
			when: { patches in
				patches(
					patch: \KeychainSearcher.searchForItems,
					with: alwaysThrowing(KeychainItemSearchFailed.error())
				)
			},
			executing: { (feature: Keychain) in
				try feature.setup(keychainName: self.keychainName, keychainPassword: self.keychainPassword)
			}
		)
	}

	func testShouldModifyAccess() async {
		await test(
			SystemKeychain.loader(),
			executedPrepared: 1,
			when: { patches, executed in
				patches(
					patch: \KeychainSearcher.searchForItems,
					with: always(.empty)
				)
				patches(
					patch: \KeychainItemAccessManager.modifyAccess,
					with: { _, password, customPartitions in
						XCTAssertEqual(password, self.keychainPassword)
						XCTAssertEqual(customPartitions, self.customPartitions)
						executed()
					}
				)
			},
			executing: { (feature: Keychain) in
				try feature.setup(keychainName: self.keychainName, keychainPassword: self.keychainPassword)
				try feature.setACLs(using: self.keychainPassword, with: self.customPartitions)
			}
		)
	}

	func testShouldImportCertificateIntoKeychain() async {
		let importExpectation = expectation(description: "Should attempt to import certificate")
		let createParametersExpectation = expectation(description: "Should attempt to create parameters")
		let prepareOptionsExpectation = expectation(description: "Should attempt to prepare options")
		await test(
			SystemKeychain.loader(),
			when: { patches in
				patches(
					patch: \SecItemAPI.createParameters,
					with: { password, _ in
						XCTAssertEqual(password, self.keychainPassword)
						createParametersExpectation.fulfill()
						return SecItemImportExportKeyParameters()
					}
				)
				patches(
					patch: \SecItemAPI.import,
					with: { certificate, _, _ in
						XCTAssertEqual(certificate, self.certificateData)
						importExpectation.fulfill()
						return errSecSuccess
					}
				)
				patches(
					patch: \KeychainItemAccessManager.prepareAccessOptions,
					with: { apps in
						XCTAssertEqual(apps, self.apps)
						prepareOptionsExpectation.fulfill()
						return .empty
					}
				)
			},
			executing: { (feature: Keychain) in
				try feature.setup(keychainName: self.keychainName, keychainPassword: self.keychainPassword)
				try feature.import(self.certificateData, using: self.keychainPassword, for: self.apps)
			}
		)
		await fulfillment(of: [importExpectation, createParametersExpectation, prepareOptionsExpectation], timeout: 1)
	}
}

extension KeychainTests {
	var keychainName: String {
		"name"
	}
	var keychainPassword: String {
		"password"
	}
	var customPartitions: [String] {
		["a", "b"]
	}
	var apps: [String] {
		["app1", "app2"]
	}
	var certificateData: Data {
		Data(base64Encoded: "testData")!
	}
}
