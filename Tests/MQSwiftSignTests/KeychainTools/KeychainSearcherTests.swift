import Foundation
@testable import MQSwiftSign

final class KeychainSearcherTests: FeatureTests {
	func testShouldFailOnSearchFailed() async {
		await test(
			KeychainSearcher.system(),
			throws: KeychainItemSearchFailed.self,
			when: { patches in
				patches(
					patch: \SecKeychainItemAPI.search,
					with: alwaysThrowing(KeychainItemSearchFailed.error())
				)
			},
			executing: { (feature: KeychainSearcher) in
				try feature.searchForItems(.empty)
			}
		)
	}

	func testShouldReturnKeychainItem() async {
		await test(
			KeychainSearcher.system(),
			executedPrepared: 1,
			when: { patches, executed in
				patches(
					patch: \SecKeychainItemAPI.search,
					with: { query in
						XCTAssertEqual(query.count, 5) // query parameters count
						executed()
						return .empty
					}
				)
			},
			executing: { (feature: KeychainSearcher) in
				try feature.searchForItems(.empty)
			}
		)
	}
}
