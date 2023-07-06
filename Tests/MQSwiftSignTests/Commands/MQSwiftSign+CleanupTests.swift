import Foundation

@testable import MQSwiftSign

final class MQSwiftSign_Cleanup_Tests: FeatureTests {
	func testShouldFailIfNoKeychainNameIsStored() async {
		await test(
			patches: { patches in
				patches(
					patch: \Preferences.get,
					with: always(nil)
				)
			},
			throws: KeychainDeletionFailed.self,
			execute: { features in
				let sut = try MQSwiftSign.Cleanup.parse([])
				try sut.run(features)
			}
		)
	}

	func testShouldAttemptToLoadKeychain() async {
		await test(
			patches: { patches in
				patches(
					patch: \Preferences.get,
					with: { _ in self.keychainName }
				)
				patches(
					patch: \SecKeychainAPI.get,
					with: always(nil)
				)
				patches(
					patch: \SecKeychainAPI.forceDelete,
					with: alwaysThrowing(KeychainDeletionFailed.error())
				)
			},
			throws: KeychainDeletionFailed.self,
			execute: { features in
				let sut = try MQSwiftSign.Cleanup.parse([])
				try sut.run(features)
			}
		)
	}

	func testShouldAttemptToDeleteKeychain() async {
		await test(
			patches: { patches, executed in
				patches(
					patch: \Preferences.get,
					with: { _ in self.keychainName }
				)
				patches(
					patch: \SecKeychainAPI.get,
					with: { keychainName in
						executed(keychainName)
						return self.keychainMock
					}
				)
				patches(
					patch: \SecKeychainAPI.forceDelete,
					with: { keychain in
						XCTAssertEqual(keychain, self.keychainMock)
					}
				)
			},
			executedPreparedUsing: self.keychainName,
			execute: { features in
				let sut = try MQSwiftSign.Cleanup.parse([])
				try sut.run(features)
			}
		)
	}
}

extension MQSwiftSign_Cleanup_Tests {
	var keychainName: String { "keychainName" }
	var keychainMock: CFWrapper<SecKeychain> { .empty }
}
