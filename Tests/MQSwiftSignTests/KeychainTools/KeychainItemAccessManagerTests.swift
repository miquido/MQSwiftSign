import Foundation
@testable import MQSwiftSign

class KeychainItemAccessManagerTests: FeatureTests {
	override func commonPatches(_ patches: FeaturePatches) {
		super.commonPatches(patches)
		patches(use: SecAccessAPI.placeholder)
	}

	func testShouldPrepareOptions() async {
		await test(
			SystemKeychainItemAccessManager.loader(),
			executedPrepared: 1,
			when: { patches, executed in
				patches(
					patch: \SecAccessAPI.create,
					with: { apps in
						XCTAssertEqual(apps.count, SystemKeychainItemAccessManager.defaultApps.count + self.customApps.count)
						executed()
						return .empty
					}
				)
			},
			executing: { (feature: KeychainItemAccessManager) in
				try feature.prepareAccessOptions(self.customApps)
			}
		)
	}

	func testShouldFailToPrepareOptionsOnAccessFailed() async {
		await test(
			SystemKeychainItemAccessManager.loader(),
			throws: AccessFailed.self,
			when: { patches in
				patches(
					patch: \SecAccessAPI.create,
					with: alwaysThrowing(AccessFailed.error())
				)
			},
			executing: { (feature: KeychainItemAccessManager) in
				try feature.prepareAccessOptions(self.customApps)
			}
		)
	}

	func testShouldFailToModifyAccessOnAccessFailedFromSecAccessAPI() async {
		await test(
			SystemKeychainItemAccessManager.loader(),
			throws: AccessFailed.self,
			when: { patches in
				patches(
					patch: \SecAccessAPI.get,
					with: alwaysThrowing(AccessFailed.error())
				)
			},
			executing: { (feature: KeychainItemAccessManager) in
				try feature.modifyAccess(using: .empty, password: self.password, customPartitions: self.customApps)
			}
		)
	}

	func testShouldFailToModifyAccessOnAccessFailedFromSecACLAPI() async {
		await test(
			SystemKeychainItemAccessManager.loader(),
			throws: AccessFailed.self,
			when: { patches in
				patches(
					patch: \SecAccessAPI.get,
					with: { _ in
						return .empty
					}
				)
				patches(
					patch: \SecACLAPI.contents,
					with: alwaysThrowing(AccessFailed.error())
				)
			},
			executing: { (feature: KeychainItemAccessManager) in
				try feature.modifyAccess(using: .empty, password: self.password, customPartitions: self.customApps)
			}
		)
	}

	func testShouldNotAttemptSetAccessWhenNoItemsAreFound() async {
		await test(
			SystemKeychainItemAccessManager.loader(),
			executedPrepared: 0,
			when: { patches, executed in
				patches(
					patch: \SecAccessAPI.get,
					with: always(.empty)
				)
				patches(
					patch: \SecACLAPI.contents,
					with: always([])
				)
			},
			executing: { (feature: KeychainItemAccessManager) in
				try feature.modifyAccess(using: .empty, password: self.password, customPartitions: self.customApps)
			}
		)
	}

	func testShouldNotAttemptSetAccessWhenACLListCannotBeLoaded() async {
		await test(
			SystemKeychainItemAccessManager.loader(),
			executedPrepared: 0,
			when: { patches, executed in
				patches(
					patch: \SecAccessAPI.get,
					with: always(.empty)
				)
				patches(
					patch: \SecACLAPI.contents,
					with: always([CFWrapper<SecACL>.empty])
				)
				patches(
					patch: \SecACLAPI.list,
					with: always(nil)
				)
			},
			executing: { (feature: KeychainItemAccessManager) in
				try feature.modifyAccess(using: .empty, password: self.password, customPartitions: self.customApps)
			}
		)
	}

	func testShouldNotAttemptSetAccessWhenACLListIsInvalid() async {
		await test(
			SystemKeychainItemAccessManager.loader(),
			throws: NSError.self,
			when: { patches in
				patches(
					patch: \SecAccessAPI.get,
					with: always(.empty)
				)
				patches(
					patch: \SecACLAPI.contents,
					with: always([CFWrapper<SecACL>.empty])
				)
				patches(
					patch: \SecACLAPI.list,
					with: always((nil, Data(), SecKeychainPromptSelector.invalid))
				)
			},
			executing: { (feature: KeychainItemAccessManager) in
				try feature.modifyAccess(using: .empty, password: self.password, customPartitions: self.customApps)
			}
		)
	}

	func testShouldNotAttemptSetAccessWhenSetACLFails() async {
		await test(
			SystemKeychainItemAccessManager.loader(),
			throws: AccessFailed.self,
			when: { patches in
				patches(
					patch: \SecAccessAPI.get,
					with: always(.empty)
				)
				patches(
					patch: \SecACLAPI.contents,
					with: always([CFWrapper<SecACL>.empty])
				)
				patches(
					patch: \SecACLAPI.list,
					with: { _ in
						(nil, self.xmlData, SecKeychainPromptSelector.invalid)
					}
				)
				patches(
					patch: \SecACLAPI.set,
					with: alwaysThrowing(AccessFailed.error())
				)
			},
			executing: { (feature: KeychainItemAccessManager) in
				try feature.modifyAccess(using: .empty, password: self.password, customPartitions: self.customApps)
			}
		)
	}

	func testShouldCallSetAccess() async {
		await test(
			SystemKeychainItemAccessManager.loader(),
			executedPrepared: 1,
			when: { patches, executed in
				patches(
					patch: \SecAccessAPI.get,
					with: always(.empty)
				)
				patches(
					patch: \SecACLAPI.contents,
					with: always([.empty])
				)
				patches(
					patch: \SecACLAPI.list,
					with: { _ in
						(nil, self.xmlData, SecKeychainPromptSelector.invalid)
					}
				)
				patches(
					patch: \SecACLAPI.set,
					with: noop
				)
				patches(
					patch: \SecKeychainItemAPI.setAccessWithPassword,
					with: { _, _, _ in
						executed()
					}
				)
			},
			executing: { (feature: KeychainItemAccessManager) in
				try feature.modifyAccess(using: .empty, password: self.password, customPartitions: self.customApps)
			}
		)
	}
}

private extension KeychainItemAccessManagerTests {
	var customApps: [String] { ["/bin/sh", "/bin/echo"] }
	var password: String { "password" }
	var xmlContents: [String: [String: String]] { ["xml": ["key": "value"]] }
	var xmlData: Data { try! PropertyListSerialization.data(fromPropertyList: xmlContents, format: .xml, options: 0) }
}
